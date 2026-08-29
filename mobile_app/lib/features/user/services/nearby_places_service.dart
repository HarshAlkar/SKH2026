import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/services/api_service.dart';
import '../../../core/sync/local_store.dart';
import '../../../core/sync/offline_api.dart';
import '../models/nearby_place.dart';

class NearbyPlacesResult {
  final List<NearbyPlace> places;
  final bool fromCache;
  final bool offline;
  final String? error;
  final NearbyLoadState state;
  final double? lat;
  final double? lng;
  final int radiusM;

  const NearbyPlacesResult({
    required this.places,
    required this.state,
    this.fromCache = false,
    this.offline = false,
    this.error,
    this.lat,
    this.lng,
    this.radiusM = 5000,
  });
}

/// Fetches nearby healthcare via Django Places proxy with local cache.
class NearbyPlacesService {
  NearbyPlacesService({
    ApiService? api,
    LocalStore? store,
  })  : _api = api ?? ApiService(),
        _store = store ?? LocalStore.instance;

  final ApiService _api;
  final LocalStore _store;

  static const int defaultRadiusM = 5000;
  static const Duration cacheTtl = Duration(minutes: 10);
  static const double skipRefreshMeters = 200;

  Position? _lastFetchPosition;
  DateTime? _lastFetchAt;
  List<NearbyPlace> _memoryCache = [];
  int _lastRadiusM = defaultRadiusM;

  String _bucketKey(double lat, double lng, int radiusM) {
    final latB = (lat * 100).round() / 100;
    final lngB = (lng * 100).round() / 100;
    return 'nearby_places:$latB:$lngB:$radiusM';
  }

  bool shouldSkipNetworkRefresh(Position position, {int radiusM = defaultRadiusM}) {
    if (_lastFetchPosition == null || _lastFetchAt == null || _memoryCache.isEmpty) {
      return false;
    }
    if (radiusM != _lastRadiusM) return false;
    final age = DateTime.now().difference(_lastFetchAt!);
    if (age > cacheTtl) return false;
    final moved = Geolocator.distanceBetween(
      _lastFetchPosition!.latitude,
      _lastFetchPosition!.longitude,
      position.latitude,
      position.longitude,
    );
    return moved < skipRefreshMeters;
  }

  List<NearbyPlace> filterByCategory(List<NearbyPlace> places, String category) {
    if (category == 'All' || category.isEmpty) return places;
    final key = _categoryKey(category);
    return places.where((p) => p.category == key).toList();
  }

  String _categoryKey(String label) {
    switch (label) {
      case 'Hospitals':
        return 'hospitals';
      case 'Clinics':
        return 'clinics';
      case 'Labs':
        return 'labs';
      case 'Pharmacies':
      case 'Medical Stores':
        return 'pharmacies';
      default:
        return 'all';
    }
  }

  Future<NearbyPlacesResult> fetchNearby({
    required double lat,
    required double lng,
    int radiusM = defaultRadiusM,
    bool forceRefresh = false,
    Position? position,
  }) async {
    final cacheKey = _bucketKey(lat, lng, radiusM);

    if (!forceRefresh &&
        position != null &&
        shouldSkipNetworkRefresh(position, radiusM: radiusM)) {
      return NearbyPlacesResult(
        places: List.unmodifiable(_memoryCache),
        state: _memoryCache.isEmpty ? NearbyLoadState.empty : NearbyLoadState.ready,
        fromCache: true,
        lat: lat,
        lng: lng,
        radiusM: radiusM,
      );
    }

    try {
      final data = await _api.get(
        '/places/nearby/?lat=$lat&lng=$lng&radius_m=$radiusM&category=all',
        timeout: const Duration(seconds: 25),
      );
      if (data is! Map) {
        throw Exception('Unexpected places response');
      }
      final map = Map<String, dynamic>.from(data);
      final stateCode = '${map['result_state'] ?? 'OK'}';
      if (stateCode == 'API_ERROR' || stateCode == 'NETWORK_ERROR') {
        throw Exception(map['error']?.toString() ?? 'Places request failed');
      }

      final list = map['places'];
      final places = <NearbyPlace>[];
      if (list is List) {
        for (final raw in list) {
          if (raw is Map) {
            places.add(NearbyPlace.fromJson(Map<String, dynamic>.from(raw)));
          }
        }
      }

      final vr = await _fetchVitalReachFacilities(lat, lng);
      final merged = _mergeAndSort(places, vr);

      final payload = {
        'fetched_at': DateTime.now().toIso8601String(),
        'lat': lat,
        'lng': lng,
        'radius_m': radiusM,
        'places': merged.map((p) => p.toJson()).toList(),
      };
      await _store.putCache(cacheKey, payload);
      // Also keep a stable "last successful" key for offline when GPS buckets differ slightly.
      await _store.putCache('nearby_places:last', payload);

      _memoryCache = merged;
      _lastFetchAt = DateTime.now();
      _lastRadiusM = radiusM;
      if (position != null) {
        _lastFetchPosition = position;
      } else {
        _lastFetchPosition = Position(
          latitude: lat,
          longitude: lng,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }

      return NearbyPlacesResult(
        places: List.unmodifiable(merged),
        state: merged.isEmpty ? NearbyLoadState.empty : NearbyLoadState.ready,
        lat: lat,
        lng: lng,
        radiusM: radiusM,
      );
    } catch (e) {
      debugPrint('NearbyPlacesService: $e');
      final cached = await _loadCached(cacheKey) ?? await _loadCached('nearby_places:last');
      if (cached != null && cached.places.isNotEmpty) {
        _memoryCache = cached.places;
        return NearbyPlacesResult(
          places: List.unmodifiable(cached.places),
          state: NearbyLoadState.offlineCached,
          fromCache: true,
          offline: true,
          error: e.toString(),
          lat: cached.lat,
          lng: cached.lng,
          radiusM: cached.radiusM,
        );
      }

      final msg = e.toString().toLowerCase();
      final isNetwork = msg.contains('network') ||
          msg.contains('socket') ||
          msg.contains('timeout') ||
          msg.contains('connection') ||
          msg.contains('failed host');
      return NearbyPlacesResult(
        places: const [],
        state: isNetwork ? NearbyLoadState.networkError : NearbyLoadState.apiError,
        error: e.toString().replaceFirst('Exception: ', ''),
        lat: lat,
        lng: lng,
        radiusM: radiusM,
      );
    }
  }

  Future<NearbyPlacesResult?> _loadCached(String key) async {
    final raw = await _store.getCache(key);
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final list = map['places'];
    if (list is! List || list.isEmpty) return null;
    final places = <NearbyPlace>[];
    for (final item in list) {
      if (item is Map) {
        places.add(NearbyPlace.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    if (places.isEmpty) return null;
    return NearbyPlacesResult(
      places: places,
      state: NearbyLoadState.offlineCached,
      fromCache: true,
      offline: true,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      radiusM: (map['radius_m'] as num?)?.toInt() ?? defaultRadiusM,
    );
  }

  Future<List<NearbyPlace>> _fetchVitalReachFacilities(double lat, double lng) async {
    try {
      final data = await OfflineApi.instance.get('/stock/map/');
      final list = data is List ? data : <dynamic>[];
      final out = <NearbyPlace>[];
      for (final raw in list) {
        if (raw is! Map) continue;
        final fLat = double.tryParse('${raw['lat'] ?? ''}');
        final fLng = double.tryParse('${raw['lng'] ?? ''}');
        if (fLat == null || fLng == null) continue;
        final distanceM = Geolocator.distanceBetween(lat, lng, fLat, fLng);
        if (distanceM > 25000) continue;
        final low = int.tryParse('${raw['low_stock'] ?? 0}') ?? 0;
        final outStock = int.tryParse('${raw['out_of_stock'] ?? 0}') ?? 0;
        String badge = 'In Stock';
        if (outStock > 0 && low == 0) badge = 'Some Out';
        if (low > 0) badge = 'Low Stock';
        if ((int.tryParse('${raw['total_batches'] ?? 0}') ?? 0) == 0) {
          badge = 'No Stock Data';
        }
        out.add(
          NearbyPlace(
            id: 'vr-${raw['id']}',
            name: '${raw['label'] ?? 'VitalReach Facility'} (VitalReach)',
            category: 'pharmacies',
            lat: fLat,
            lng: fLng,
            distanceM: distanceM,
            address: '${raw['village'] ?? ''} · Low:$low Out:$outStock · $badge',
            stockBadge: badge,
            vitalReach: true,
          ),
        );
      }
      return out;
    } catch (e) {
      debugPrint('VitalReach facilities: $e');
      return [];
    }
  }

  List<NearbyPlace> _mergeAndSort(List<NearbyPlace> google, List<NearbyPlace> vr) {
    final seen = <String>{};
    final merged = <NearbyPlace>[];
    for (final p in [...vr, ...google]) {
      final key = p.id.isNotEmpty ? p.id : '${p.lat},${p.lng}';
      if (seen.contains(key)) continue;
      seen.add(key);
      merged.add(p);
    }
    merged.sort((a, b) => a.distanceM.compareTo(b.distanceM));
    return merged;
  }
}
