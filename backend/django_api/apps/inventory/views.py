from datetime import timedelta
from math import asin, cos, radians, sin, sqrt

from django.db.models import F, Q, Sum
from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import (
    HealthcareFacility,
    MedicineCatalog,
    Supplier,
    StockBatch,
    StockMovement,
)
from .permissions import CanReadStock, IsStockWriter
from .serializers import (
    HealthcareFacilitySerializer,
    MedicineCatalogSerializer,
    SupplierSerializer,
    StockBatchSerializer,
    StockMovementSerializer,
    StockAdjustSerializer,
)
from .services import facility_stock_health


def _haversine_km(lat1, lng1, lat2, lng2):
    r = 6371.0
    dlat = radians(lat2 - lat1)
    dlng = radians(lng2 - lng1)
    a = sin(dlat / 2) ** 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlng / 2) ** 2
    return 2 * r * asin(sqrt(a))


def user_facility_ids(user):
    """Facilities this user may write to (None = all for staff)."""
    if user.is_staff:
        return None
    ids = set()
    if getattr(user, 'role', None) == 'medical_staff':
        profile = getattr(user, 'medical_staff_profile', None)
        if profile and profile.facility_id:
            ids.add(profile.facility_id)
    if getattr(user, 'role', None) == 'asha_worker':
        asha = getattr(user, 'asha_profile', None)
        if asha:
            village = (asha.assigned_village or user.village or '').strip()
            phc = (asha.phc_center or '').strip()
            qs = HealthcareFacility.objects.filter(is_active=True)
            matched = qs.none()
            if village:
                matched = qs.filter(Q(village__iexact=village) | Q(name__icontains=village))
            if phc:
                matched = matched | qs.filter(Q(name__icontains=phc) | Q(village__icontains=phc))
            ids.update(matched.values_list('id', flat=True))
            if not ids and asha.district:
                ids.update(
                    qs.filter(district__iexact=asha.district).values_list('id', flat=True)[:3]
                )
    return ids


def scope_batches(user, qs=None):
    qs = qs if qs is not None else StockBatch.objects.select_related(
        'catalog', 'facility', 'supplier',
    )
    facility_ids = user_facility_ids(user)
    role = getattr(user, 'role', None)
    if user.is_staff or role in ('user', 'doctor'):
        return qs
    if facility_ids is not None:
        if not facility_ids:
            return qs.none()
        return qs.filter(facility_id__in=facility_ids)
    return qs


class DashboardView(APIView):
    permission_classes = [IsAuthenticated, CanReadStock]

    def get(self, request):
        batches = scope_batches(request.user)
        today = timezone.localdate()
        soon = today + timedelta(days=30)
        total_medicines = batches.values('catalog_id').distinct().count()
        stock_units = batches.aggregate(s=Sum('quantity'))['s'] or 0
        low = batches.filter(quantity__gt=0, quantity__lte=F('reorder_level')).count()
        out = batches.filter(quantity=0).count()
        expiring = batches.filter(expiry_date__gte=today, expiry_date__lte=soon, quantity__gt=0).count()
        expired = batches.filter(expiry_date__lt=today).count()

        since = timezone.now() - timedelta(days=30)
        movements = StockMovement.objects.filter(
            batch_id__in=batches.values_list('id', flat=True),
            created_at__gte=since,
        )
        chart = []
        for i in range(30):
            day = (timezone.localdate() - timedelta(days=29 - i))
            day_m = movements.filter(created_at__date=day)
            added = day_m.filter(action='add').aggregate(s=Sum('quantity'))['s'] or 0
            sold = day_m.filter(action__in=['remove', 'disposal', 'return']).aggregate(
                s=Sum('quantity')
            )['s'] or 0
            chart.append({'date': day.isoformat(), 'added': added, 'sold': sold})

        urgent = []
        for b in batches.filter(quantity=0)[:5]:
            urgent.append({
                'id': b.id,
                'medicine_name': b.catalog.display_name,
                'batch_no': b.batch_no,
                'kind': 'out_of_stock',
                'label': 'OUT OF STOCK',
                'quantity': 0,
            })
        for b in batches.filter(
            expiry_date__gte=today, expiry_date__lte=soon, quantity__gt=0,
        ).order_by('expiry_date')[:5]:
            urgent.append({
                'id': b.id,
                'medicine_name': b.catalog.display_name,
                'batch_no': b.batch_no,
                'kind': 'expiring',
                'label': f'EXPIRING IN {b.days_to_expiry} DAYS',
                'quantity': b.quantity,
                'days_left': b.days_to_expiry,
            })
        for b in batches.filter(
            quantity__gt=0, quantity__lte=F('reorder_level'),
        ).order_by('quantity')[:5]:
            urgent.append({
                'id': b.id,
                'medicine_name': b.catalog.display_name,
                'batch_no': b.batch_no,
                'kind': 'low_stock',
                'label': f'LOW STOCK ({b.quantity} UNITS)',
                'quantity': b.quantity,
            })

        return Response({
            'total_medicines': total_medicines,
            'stock_units': stock_units,
            'low_stock': low,
            'out_of_stock': out,
            'expiring_soon': expiring,
            'expired': expired,
            'movement_chart': chart,
            'urgent_alerts': urgent[:12],
        })


class CatalogViewSet(viewsets.ModelViewSet):
    serializer_class = MedicineCatalogSerializer
    permission_classes = [IsAuthenticated, IsStockWriter]
    http_method_names = ['get', 'post', 'patch', 'head', 'options']

    def get_queryset(self):
        qs = MedicineCatalog.objects.all()
        q = (self.request.query_params.get('q') or '').strip()
        if q:
            qs = qs.filter(Q(name__icontains=q) | Q(sku__icontains=q) | Q(strength__icontains=q))
        category = (self.request.query_params.get('category') or '').strip()
        if category:
            qs = qs.filter(category__iexact=category)
        if self.request.query_params.get('active') == '1':
            qs = qs.filter(is_active=True)
        return qs


class BatchViewSet(viewsets.ModelViewSet):
    serializer_class = StockBatchSerializer
    permission_classes = [IsAuthenticated, IsStockWriter]
    http_method_names = ['get', 'post', 'patch', 'head', 'options']

    def get_queryset(self):
        qs = scope_batches(self.request.user)
        q = (self.request.query_params.get('q') or '').strip()
        if q:
            qs = qs.filter(
                Q(catalog__name__icontains=q)
                | Q(catalog__sku__icontains=q)
                | Q(batch_no__icontains=q)
            )
        status_f = (self.request.query_params.get('status') or '').strip()
        today = timezone.localdate()
        soon = today + timedelta(days=30)
        if status_f == 'out_of_stock':
            qs = qs.filter(quantity=0)
        elif status_f == 'low_stock':
            qs = qs.filter(quantity__gt=0, quantity__lte=F('reorder_level'))
        elif status_f == 'expiring':
            qs = qs.filter(expiry_date__gte=today, expiry_date__lte=soon, quantity__gt=0)
        elif status_f == 'expired':
            qs = qs.filter(expiry_date__lt=today)
        elif status_f == 'in_stock':
            qs = qs.filter(quantity__gt=F('reorder_level'), expiry_date__gt=soon)
        category = (self.request.query_params.get('category') or '').strip()
        if category:
            qs = qs.filter(catalog__category__iexact=category)
        facility_id = self.request.query_params.get('facility')
        if facility_id:
            qs = qs.filter(facility_id=facility_id)
        return qs


class SupplierViewSet(viewsets.ModelViewSet):
    serializer_class = SupplierSerializer
    permission_classes = [IsAuthenticated, IsStockWriter]
    http_method_names = ['get', 'post', 'patch', 'head', 'options']
    queryset = Supplier.objects.all()

    def get_queryset(self):
        qs = Supplier.objects.all()
        q = (self.request.query_params.get('q') or '').strip()
        if q:
            qs = qs.filter(name__icontains=q)
        return qs


class FacilityViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = HealthcareFacilitySerializer
    permission_classes = [IsAuthenticated, CanReadStock]

    def get_queryset(self):
        qs = HealthcareFacility.objects.filter(is_active=True)
        ids = user_facility_ids(self.request.user)
        role = getattr(self.request.user, 'role', None)
        if self.request.user.is_staff or role in ('user', 'doctor'):
            return qs
        if ids is not None:
            if not ids:
                return qs
            return qs.filter(id__in=ids)
        return qs


class HistoryView(APIView):
    permission_classes = [IsAuthenticated, CanReadStock]

    def get(self, request):
        batch_ids = scope_batches(request.user).values_list('id', flat=True)
        qs = StockMovement.objects.filter(batch_id__in=batch_ids).select_related(
            'batch__catalog', 'batch__facility', 'actor',
        )
        action = (request.query_params.get('action') or '').strip()
        if action:
            qs = qs.filter(action=action)
        limit = min(int(request.query_params.get('limit') or 100), 500)
        data = StockMovementSerializer(qs[:limit], many=True).data
        return Response(data)


class ExpiryView(APIView):
    permission_classes = [IsAuthenticated, CanReadStock]

    def get(self, request):
        batches = scope_batches(request.user)
        today = timezone.localdate()
        d30 = today + timedelta(days=30)
        d60 = today + timedelta(days=60)
        return Response({
            'expired': StockBatchSerializer(
                batches.filter(expiry_date__lt=today), many=True,
            ).data,
            'within_30_days': StockBatchSerializer(
                batches.filter(expiry_date__gte=today, expiry_date__lte=d30, quantity__gt=0),
                many=True,
            ).data,
            'within_60_days': StockBatchSerializer(
                batches.filter(expiry_date__gt=d30, expiry_date__lte=d60, quantity__gt=0),
                many=True,
            ).data,
        })


class LowStockView(APIView):
    permission_classes = [IsAuthenticated, CanReadStock]

    def get(self, request):
        batches = scope_batches(request.user).filter(
            Q(quantity=0) | Q(quantity__lte=F('reorder_level'))
        )
        return Response(StockBatchSerializer(batches, many=True).data)


class AdjustStockView(APIView):
    permission_classes = [IsAuthenticated, IsStockWriter]

    def post(self, request):
        if getattr(request.user, 'role', None) in ('user', 'doctor') and not request.user.is_staff:
            return Response({'error': 'Not allowed to update stock.'}, status=status.HTTP_403_FORBIDDEN)
        ser = StockAdjustSerializer(data=request.data, context={'request': request})
        ser.is_valid(raise_exception=True)
        batch = ser.validated_data['batch']
        allowed = user_facility_ids(request.user)
        if allowed is not None and batch.facility_id not in allowed and not request.user.is_staff:
            if allowed:
                return Response(
                    {'error': 'You cannot update stock for this facility.'},
                    status=status.HTTP_403_FORBIDDEN,
                )
        result = ser.save()
        movement = result['movement']
        return Response({
            'created': result['created'],
            'movement': StockMovementSerializer(movement).data,
            'batch': StockBatchSerializer(movement.batch).data,
        }, status=status.HTTP_201_CREATED if result['created'] else status.HTTP_200_OK)


class SyncStockView(APIView):
    permission_classes = [IsAuthenticated, IsStockWriter]

    def post(self, request):
        items = request.data.get('items') or request.data
        if not isinstance(items, list):
            return Response(
                {'error': 'Expected a list of adjustments under "items".'},
                status=400,
            )
        results = []
        for raw in items:
            ser = StockAdjustSerializer(data=raw, context={'request': request})
            if not ser.is_valid():
                results.append({'ok': False, 'errors': ser.errors, 'client_id': raw.get('client_id')})
                continue
            batch = ser.validated_data['batch']
            allowed = user_facility_ids(request.user)
            if (
                allowed is not None
                and batch.facility_id not in allowed
                and not request.user.is_staff
            ):
                results.append({
                    'ok': False,
                    'errors': {'facility': 'Not allowed'},
                    'client_id': str(ser.validated_data['client_id']),
                })
                continue
            result = ser.save()
            results.append({
                'ok': True,
                'created': result['created'],
                'client_id': str(result['movement'].client_id),
                'movement': StockMovementSerializer(result['movement']).data,
                'batch': StockBatchSerializer(result['movement'].batch).data,
            })
        from apps.security_audit.audit import log_security_event
        log_security_event(
            request, action='stock_sync',
            object_type='StockMovement',
            metadata={'item_count': len(items)},
        )
        return Response({'results': results})


class AvailabilityView(APIView):
    permission_classes = [IsAuthenticated, CanReadStock]

    def get(self, request):
        q = (request.query_params.get('q') or '').strip()
        village = (request.query_params.get('village') or '').strip()
        lat = request.query_params.get('lat')
        lng = request.query_params.get('lng')
        radius_km = float(request.query_params.get('radius_km') or 25)

        batches = StockBatch.objects.select_related('catalog', 'facility').filter(
            facility__is_active=True,
        )
        if q:
            batches = batches.filter(
                Q(catalog__name__icontains=q) | Q(catalog__sku__icontains=q)
            )
        if village:
            batches = batches.filter(
                Q(facility__village__icontains=village) | Q(facility__name__icontains=village)
            )

        grouped = {}
        for b in batches:
            key = (b.facility_id, b.catalog_id)
            if key not in grouped:
                grouped[key] = {
                    'facility_id': b.facility_id,
                    'facility_name': b.facility.name,
                    'facility_type': b.facility.facility_type,
                    'village': b.facility.village,
                    'latitude': b.facility.latitude,
                    'longitude': b.facility.longitude,
                    'catalog_id': b.catalog_id,
                    'medicine_name': b.catalog.display_name,
                    'sku': b.catalog.sku,
                    'unit': b.catalog.unit,
                    'quantity': 0,
                    'status': 'out_of_stock',
                    'nearest_expiry': None,
                }
            g = grouped[key]
            g['quantity'] += b.quantity
            if g['nearest_expiry'] is None or b.expiry_date < g['nearest_expiry']:
                g['nearest_expiry'] = b.expiry_date

        rows = list(grouped.values())
        for g in rows:
            if g['quantity'] <= 0:
                g['status'] = 'out_of_stock'
            elif g['quantity'] <= 20:
                g['status'] = 'low_stock'
            else:
                g['status'] = 'in_stock'
            if g['nearest_expiry']:
                g['nearest_expiry'] = g['nearest_expiry'].isoformat()
            if lat and lng and g['latitude'] is not None and g['longitude'] is not None:
                try:
                    dist = _haversine_km(float(lat), float(lng), g['latitude'], g['longitude'])
                    g['distance_km'] = round(dist, 2)
                except (TypeError, ValueError):
                    g['distance_km'] = None
            else:
                g['distance_km'] = None

        if lat and lng:
            rows = [
                r for r in rows
                if r.get('distance_km') is None or r['distance_km'] <= radius_km
            ]
            rows.sort(key=lambda r: (r['distance_km'] is None, r['distance_km'] or 9999))

        return Response(rows)


class FacilitiesMapView(APIView):
    permission_classes = [IsAuthenticated, CanReadStock]

    def get(self, request):
        facilities = HealthcareFacility.objects.filter(
            is_active=True,
            latitude__isnull=False,
            longitude__isnull=False,
        )
        markers = []
        for f in facilities:
            health = facility_stock_health(f)
            markers.append({
                'id': f.id,
                'type': 'pharmacy',
                'lat': f.latitude,
                'lng': f.longitude,
                'label': f.name,
                'village': f.village,
                'facility_type': f.facility_type,
                **health,
            })
        return Response(markers)
