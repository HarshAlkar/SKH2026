"""Server-side Google Places proxy — API key never leaves the backend."""

from __future__ import annotations

import json
import math
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Any

from django.conf import settings
from django.core.cache import cache
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from apps.security_audit.audit import log_security_event

CATEGORY_TYPES: dict[str, list[str]] = {
    'hospitals': ['hospital', 'general_hospital'],
    'clinics': ['medical_clinic', 'doctor', 'medical_center'],
    'labs': ['medical_lab'],
    'pharmacies': ['pharmacy', 'drugstore'],
}

TYPE_TO_CATEGORY: dict[str, str] = {}
for cat, types in CATEGORY_TYPES.items():
    for t in types:
        TYPE_TO_CATEGORY[t] = cat

FIELD_MASK = (
    'places.id,places.displayName,places.types,places.formattedAddress,'
    'places.location,places.rating,places.userRatingCount,'
    'places.nationalPhoneNumber,places.internationalPhoneNumber,'
    'places.currentOpeningHours.openNow,places.primaryType'
)

# Short TTL to avoid hammering Places on rapid refreshes / duplicate clients.
CACHE_TTL_SECONDS = 120


def _haversine_m(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    r = 6371000.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlmb = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dlmb / 2) ** 2
    return 2 * r * math.asin(min(1.0, math.sqrt(a)))


def _classify(types: list[str], primary: str | None) -> str:
    if primary and primary in TYPE_TO_CATEGORY:
        return TYPE_TO_CATEGORY[primary]
    for t in types:
        if t in TYPE_TO_CATEGORY:
            return TYPE_TO_CATEGORY[t]
    return 'other'


def _call_search_nearby(
    api_key: str,
    lat: float,
    lng: float,
    radius_m: int,
    included_types: list[str],
) -> list[dict[str, Any]]:
    body = {
        'includedTypes': included_types,
        'maxResultCount': 20,
        'rankPreference': 'DISTANCE',
        'locationRestriction': {
            'circle': {
                'center': {'latitude': lat, 'longitude': lng},
                'radius': float(radius_m),
            }
        },
    }
    req = urllib.request.Request(
        'https://places.googleapis.com/v1/places:searchNearby',
        data=json.dumps(body).encode('utf-8'),
        headers={
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': api_key,
            'X-Goog-FieldMask': FIELD_MASK,
        },
        method='POST',
    )
    with urllib.request.urlopen(req, timeout=20) as resp:
        payload = json.loads(resp.read().decode('utf-8'))
    places = payload.get('places') or []
    return [p for p in places if isinstance(p, dict)]


def _normalize_place(raw: dict[str, Any], user_lat: float, user_lng: float) -> dict[str, Any] | None:
    loc = raw.get('location') or {}
    try:
        lat = float(loc.get('latitude'))
        lng = float(loc.get('longitude'))
    except (TypeError, ValueError):
        return None

    types = [t for t in (raw.get('types') or []) if isinstance(t, str)]
    primary = raw.get('primaryType') if isinstance(raw.get('primaryType'), str) else None
    category = _classify(types, primary)

    display = raw.get('displayName') or {}
    name = ''
    if isinstance(display, dict):
        name = (display.get('text') or '').strip()
    if not name:
        name = 'Unnamed facility'

    phone = (
        (raw.get('nationalPhoneNumber') or raw.get('internationalPhoneNumber') or '')
    )
    if not isinstance(phone, str):
        phone = ''

    hours = raw.get('currentOpeningHours') or {}
    open_now = hours.get('openNow') if isinstance(hours, dict) else None

    rating = raw.get('rating')
    try:
        rating_f = float(rating) if rating is not None else None
    except (TypeError, ValueError):
        rating_f = None

    distance_m = _haversine_m(user_lat, user_lng, lat, lng)
    place_id = (raw.get('id') or '').replace('places/', '') if isinstance(raw.get('id'), str) else ''

    return {
        'place_id': place_id,
        'name': name,
        'category': category,
        'types': types,
        'lat': lat,
        'lng': lng,
        'distance_m': round(distance_m, 1),
        'address': (raw.get('formattedAddress') or '').strip(),
        'open_now': open_now,
        'phone': phone.strip(),
        'rating': rating_f,
        'user_rating_count': raw.get('userRatingCount'),
    }


class PlacesStatusView(APIView):
    """SAFE diagnostic — never returns the API key."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        key = getattr(settings, 'GOOGLE_PLACES_API_KEY', '') or ''
        return Response({
            'places_configured': bool(key.strip()),
            'default_radius_m': int(getattr(settings, 'NEARBY_RADIUS_M', 5000)),
        })


class NearbyPlacesView(APIView):
    permission_classes = [IsAuthenticated]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'places'

    def get(self, request):
        api_key = getattr(settings, 'GOOGLE_PLACES_API_KEY', '') or ''
        if not api_key:
            return Response(
                {
                    'error': 'Nearby healthcare is not configured on the server.',
                    'result_state': 'API_ERROR',
                    'places_configured': False,
                },
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

        try:
            lat = float(request.query_params.get('lat'))
            lng = float(request.query_params.get('lng'))
        except (TypeError, ValueError):
            return Response(
                {'error': 'lat and lng are required numbers.', 'result_state': 'API_ERROR'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not (-90 <= lat <= 90 and -180 <= lng <= 180):
            return Response(
                {'error': 'Invalid coordinates.', 'result_state': 'API_ERROR'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        default_radius = int(getattr(settings, 'NEARBY_RADIUS_M', 5000))
        try:
            radius_m = int(request.query_params.get('radius_m') or default_radius)
        except (TypeError, ValueError):
            radius_m = default_radius
        radius_m = max(500, min(radius_m, 50000))

        category = (request.query_params.get('category') or 'all').strip().lower()
        if category not in ('all', *CATEGORY_TYPES.keys()):
            return Response(
                {
                    'error': 'category must be all, hospitals, clinics, labs, or pharmacies.',
                    'result_state': 'API_ERROR',
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Always fetch the full healthcare set once; client filters by category.
        # Fan-out per category so Places type filters stay OR-friendly and we get
        # better coverage than a single mixed-type request (max 20 each).
        cache_key = f"places_nearby:{round(lat, 2)}:{round(lng, 2)}:{radius_m}:all"
        cached = cache.get(cache_key)
        if cached is not None:
            return Response(_filter_cached(cached, category))

        raw_places: list[dict[str, Any]] = []
        errors: list[str] = []
        try:
            with ThreadPoolExecutor(max_workers=4) as pool:
                futures = {
                    pool.submit(
                        _call_search_nearby,
                        api_key,
                        lat,
                        lng,
                        radius_m,
                        types,
                    ): cat
                    for cat, types in CATEGORY_TYPES.items()
                }
                for fut in as_completed(futures):
                    cat = futures[fut]
                    try:
                        raw_places.extend(fut.result())
                    except urllib.error.HTTPError as exc:
                        errors.append(f'{cat}:{exc.code}')
                    except Exception:
                        errors.append(f'{cat}:network')
        except Exception:
            log_security_event(
                request,
                action='places_nearby',
                success=False,
                metadata={'category': category},
            )
            return Response(
                {
                    'error': 'Unable to reach Google Places. Check network connectivity.',
                    'result_state': 'NETWORK_ERROR',
                },
                status=status.HTTP_502_BAD_GATEWAY,
            )

        if not raw_places and errors:
            log_security_event(
                request,
                action='places_nearby',
                success=False,
                metadata={'errors': errors[:8]},
            )
            return Response(
                {
                    'error': 'Google Places request failed. Check server GOOGLE_PLACES_API_KEY and Places API (New).',
                    'result_state': 'API_ERROR',
                },
                status=status.HTTP_502_BAD_GATEWAY,
            )

        seen: set[str] = set()
        places_out: list[dict[str, Any]] = []
        for raw in raw_places:
            normalized = _normalize_place(raw, lat, lng)
            if normalized is None:
                continue
            pid = normalized.get('place_id') or f"{normalized['lat']},{normalized['lng']}"
            if pid in seen:
                continue
            seen.add(pid)
            places_out.append(normalized)

        places_out.sort(key=lambda p: p.get('distance_m') or 999999)

        result = {
            'places': places_out,
            'lat': lat,
            'lng': lng,
            'radius_m': radius_m,
            'category': 'all',
            'count': len(places_out),
            'fetched_at': int(time.time()),
            'places_configured': True,
            'result_state': 'OK',
        }
        cache.set(cache_key, result, CACHE_TTL_SECONDS)
        log_security_event(
            request,
            action='places_nearby',
            success=True,
            metadata={'category': category, 'count': len(places_out)},
        )
        return Response(_filter_cached(result, category))


def _filter_cached(payload: dict[str, Any], category: str) -> dict[str, Any]:
    """Return a copy filtered to the requested category (client may also filter)."""
    if category == 'all':
        out = dict(payload)
        out['category'] = 'all'
        out['count'] = len(out.get('places') or [])
        return out
    places = [
        p
        for p in (payload.get('places') or [])
        if isinstance(p, dict) and p.get('category') == category
    ]
    out = dict(payload)
    out['places'] = places
    out['category'] = category
    out['count'] = len(places)
    return out
