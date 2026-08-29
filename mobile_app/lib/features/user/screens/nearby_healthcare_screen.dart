import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/storage_service.dart';
import '../../../core/sync/offline_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../widgets/user_sidebar.dart';

class NearbyHealthcareScreen extends StatefulWidget {
  const NearbyHealthcareScreen({super.key});

  @override
  State<NearbyHealthcareScreen> createState() => _NearbyHealthcareScreenState();
}

class _NearbyHealthcareScreenState extends State<NearbyHealthcareScreen> {
  String _selectedCategory = 'Hospitals';
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _nearbyPlaces = [];
  Position? _currentPosition;
  bool _isLoading = false;
  String? _locationErrorType; // 'permission_denied', 'service_disabled', 'error'
  String? _locationErrorMessage;
  bool _isOfflineCache = false;
  bool _hasNetworkError = false;

  final Map<String, List<String>> _categoryKeywords = {
    'Hospitals': ['hospital', 'rural hospital', 'district hospital', 'general hospital'],
    'Clinics': ['clinic', 'phc', 'primary health centre', 'dispensary', 'doctor'],
    'Medical Stores': ['pharmacy', 'chemist', 'medical store', 'drugstore'],
    'Laboratories': ['laboratory', 'pathology', 'diagnostic'],
  };

  final Map<String, String> _categoryToAmenity = {
    'Hospitals': 'hospital',
    'Clinics': 'clinic|doctors',
    'Medical Stores': 'pharmacy',
    'Laboratories': 'laboratory',
  };

  @override
  void initState() {
    super.initState();
    _initLocationAndFetch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocationAndFetch() async {
    setState(() {
      _isLoading = true;
      _locationErrorType = null;
      _locationErrorMessage = null;
      _hasNetworkError = false;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationErrorType = 'service_disabled';
          _locationErrorMessage = 'Location services are disabled on your device.';
          _isLoading = false;
        });
        _loadCachedPlaces();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationErrorType = 'permission_denied';
            _locationErrorMessage =
                'Location permission was denied. Please allow location access to find healthcare facilities near you.';
            _isLoading = false;
          });
          _loadCachedPlaces();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationErrorType = 'permission_denied_forever';
          _locationErrorMessage =
              'Location permission is permanently denied. Please enable it in Settings to discover nearby healthcare.';
          _isLoading = false;
        });
        _loadCachedPlaces();
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        setState(() {
          _locationErrorType = 'error';
          _locationErrorMessage = 'Unable to determine your current GPS location. Please retry.';
          _isLoading = false;
        });
        _loadCachedPlaces();
        return;
      }

      setState(() {
        _currentPosition = position;
        _locationErrorType = null;
        _locationErrorMessage = null;
      });

      await _fetchPlaces();
    } catch (e) {
      debugPrint('Location initialization error: $e');
      setState(() {
        _locationErrorType = 'error';
        _locationErrorMessage = 'Error getting location: $e';
      });
      _loadCachedPlaces();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadCachedPlaces() {
    try {
      final cachedJson = StorageService.getStringSync('cached_nearby_$_selectedCategory');
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final decoded = jsonDecode(cachedJson);
        if (decoded is List && decoded.isNotEmpty) {
          setState(() {
            _nearbyPlaces = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
            _isOfflineCache = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading cached places: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchVitalReachFacilities() async {
    if (_currentPosition == null) return [];
    try {
      final data = await OfflineApi.instance.get('/stock/map/');
      final list = data is List ? data : <dynamic>[];
      final out = <Map<String, dynamic>>[];

      for (final raw in list) {
        if (raw is! Map) continue;
        final lat = double.tryParse('${raw['lat'] ?? ''}');
        final lng = double.tryParse('${raw['lng'] ?? ''}');
        if (lat == null || lng == null) continue;

        final rawType = (raw['facility_type'] ?? raw['type'] ?? '').toString().toLowerCase();
        
        // Filter by category
        bool matchesCategory = false;
        if (_selectedCategory == 'Hospitals' && (rawType == 'hospital' || rawType.contains('hosp'))) {
          matchesCategory = true;
        } else if (_selectedCategory == 'Clinics' && (rawType == 'phc' || rawType == 'clinic' || rawType.contains('centre'))) {
          matchesCategory = true;
        } else if (_selectedCategory == 'Medical Stores' && (rawType == 'pharmacy' || rawType.contains('store') || rawType.contains('pharma'))) {
          matchesCategory = true;
        }

        if (!matchesCategory) continue;

        final distanceInMeters = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          lat,
          lng,
        );

        if (distanceInMeters > 35000) continue; // within 35 km

        final low = int.tryParse('${raw['low_stock'] ?? 0}') ?? 0;
        final outStock = int.tryParse('${raw['out_of_stock'] ?? 0}') ?? 0;
        String badge = 'In Stock';
        if (outStock > 0 && low == 0) badge = 'Some Out';
        if (low > 0) badge = 'Low Stock';
        if ((int.tryParse('${raw['total_batches'] ?? 0}') ?? 0) == 0) {
          badge = 'Active Facility';
        }

        out.add({
          'id': 'vr-${raw['id']}',
          'name': '${raw['label'] ?? 'VitalReach Facility'} (VitalReach)',
          'category': _selectedCategory,
          'distance_m': distanceInMeters,
          'distance': _formatDistance(distanceInMeters),
          'address': '${raw['village'] ?? ''} ${raw['district'] ?? ''}'.trim().isNotEmpty
              ? '${raw['village'] ?? ''}, ${raw['district'] ?? ''}'.replaceAll(RegExp(r'^,\s*|,\s*$'), '')
              : 'VitalReach Network Health Facility',
          'lat': lat,
          'lng': lng,
          'phone': (raw['phone'] ?? '').toString(),
          'stock_badge': badge,
          'vitalreach': true,
        });
      }
      return out;
    } catch (e) {
      debugPrint('Error fetching VitalReach facilities: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchNominatimPlaces() async {
    if (_currentPosition == null) return [];

    final lat = _currentPosition!.latitude;
    final lon = _currentPosition!.longitude;

    // Viewbox ~0.35 degrees around current location (~35 km bounding box)
    final minLon = lon - 0.35;
    final maxLon = lon + 0.35;
    final minLat = lat - 0.35;
    final maxLat = lat + 0.35;

    final keywords = _categoryKeywords[_selectedCategory] ?? ['hospital'];
    final results = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    for (final term in keywords) {
      final queryUrl = Uri.https('nominatim.openstreetmap.org', '/search', {
        'format': 'json',
        'q': term,
        'bounded': '1',
        'viewbox': '$minLon,$maxLat,$maxLon,$minLat',
        'limit': '15',
        'addressdetails': '1',
        'extratags': '1',
      });

      try {
        final response = await http.get(
          queryUrl,
          headers: {'User-Agent': 'VitalReachRuralHealth/2.0 (contact@vitalreach.org)'},
        ).timeout(const Duration(seconds: 6));

        if (response.statusCode == 200) {
          final List list = jsonDecode(response.body);
          for (final item in list) {
            final placeId = '${item['place_id'] ?? item['osm_id']}';
            if (seenIds.contains(placeId)) continue;
            seenIds.add(placeId);

            final placeLat = double.tryParse('${item['lat']}');
            final placeLon = double.tryParse('${item['lon']}');
            if (placeLat == null || placeLon == null) continue;

            final distanceMeters = Geolocator.distanceBetween(lat, lon, placeLat, placeLon);
            final displayName = item['display_name']?.toString() ?? '';
            final nameParts = displayName.split(',');
            final placeName = nameParts.isNotEmpty ? nameParts.first.trim() : term;
            final address = nameParts.length > 1 ? nameParts.sublist(1, min(4, nameParts.length)).join(',').trim() : 'Nearby Healthcare Centre';

            final extratags = (item['extratags'] as Map<String, dynamic>?) ?? {};
            final realPhone = (extratags['phone'] ??
                extratags['contact:phone'] ??
                extratags['phone:mobile'] ??
                extratags['contact:mobile'] ??
                item['phone'] ??
                '').toString();

            results.add({
              'id': placeId,
              'name': placeName,
              'category': _selectedCategory,
              'distance_m': distanceMeters,
              'distance': _formatDistance(distanceMeters),
              'address': address,
              'lat': placeLat,
              'lng': placeLon,
              'phone': realPhone,
              'vitalreach': false,
            });
          }
        }
      } catch (e) {
        debugPrint('Nominatim search for "$term" error: $e');
      }

      if (results.length >= 20) break;
    }

    return results;
  }

  Future<List<Map<String, dynamic>>> _fetchOverpassPlaces() async {
    if (_currentPosition == null) return [];

    final lat = _currentPosition!.latitude;
    final lon = _currentPosition!.longitude;
    final amenity = _categoryToAmenity[_selectedCategory] ?? 'hospital';

    final overpassQuery =
        '[out:json][timeout:10];(node(around:25000,$lat,$lon)["amenity"~"$amenity"];way(around:25000,$lat,$lon)["amenity"~"$amenity"];);out center 25;';

    final endpoints = [
      'https://overpass.kumi.systems/api/interpreter',
      'https://overpass-api.de/api/interpreter',
      'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
    ];

    for (final endpoint in endpoints) {
      try {
        final url = Uri.parse('$endpoint?data=${Uri.encodeComponent(overpassQuery)}');
        final response = await http.get(
          url,
          headers: {'User-Agent': 'VitalReachHealth/2.0'},
        ).timeout(const Duration(seconds: 7));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List elements = data['elements'] ?? [];
          final results = <Map<String, dynamic>>[];

          for (final el in elements) {
            final tags = el['tags'] as Map<String, dynamic>? ?? {};
            final placeLat = (el['lat'] ?? el['center']?['lat']) as num?;
            final placeLon = (el['lon'] ?? el['center']?['lon']) as num?;
            if (placeLat == null || placeLon == null) continue;

            final distanceMeters = Geolocator.distanceBetween(
              lat,
              lon,
              placeLat.toDouble(),
              placeLon.toDouble(),
            );

            final name = tags['name'] ??
                tags['operator'] ??
                'Unnamed ${_selectedCategory.substring(0, _selectedCategory.length - 1)}';

            final address = tags['addr:street'] ??
                tags['addr:full'] ??
                tags['addr:city'] ??
                'Near GPS (${placeLat.toStringAsFixed(2)}, ${placeLon.toStringAsFixed(2)})';

            final realPhone = (tags['phone'] ??
                tags['contact:phone'] ??
                tags['phone:mobile'] ??
                tags['contact:mobile'] ??
                '').toString();

            results.add({
              'id': '${el['id']}',
              'name': name,
              'category': _selectedCategory,
              'distance_m': distanceMeters,
              'distance': _formatDistance(distanceMeters),
              'address': address,
              'lat': placeLat.toDouble(),
              'lng': placeLon.toDouble(),
              'phone': realPhone,
              'vitalreach': false,
            });
          }

          if (results.isNotEmpty) return results;
        }
      } catch (e) {
        debugPrint('Overpass endpoint $endpoint error: $e');
      }
    }

    return [];
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m away';
    }
    return '${(distanceInMeters / 1000).toStringAsFixed(1)} km away';
  }

  Future<void> _fetchPlaces() async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoading = true;
      _hasNetworkError = false;
    });

    final allPlaces = <Map<String, dynamic>>[];
    final seenNames = <String>{};

    // 1. VitalReach Backend Registered Facilities
    final vrPlaces = await _fetchVitalReachFacilities();
    for (var p in vrPlaces) {
      final key = '${p['name']}'.toLowerCase();
      if (!seenNames.contains(key)) {
        seenNames.add(key);
        allPlaces.add(p);
      }
    }

    // 2. OpenStreetMap Nominatim Discovery
    final nomPlaces = await _fetchNominatimPlaces();
    for (var p in nomPlaces) {
      final key = '${p['name']}'.toLowerCase();
      if (!seenNames.contains(key)) {
        seenNames.add(key);
        allPlaces.add(p);
      }
    }

    // 3. Fallback: Overpass API if Nominatim had few results
    if (allPlaces.length < 5) {
      final overpassPlaces = await _fetchOverpassPlaces();
      for (var p in overpassPlaces) {
        final key = '${p['name']}'.toLowerCase();
        if (!seenNames.contains(key)) {
          seenNames.add(key);
          allPlaces.add(p);
        }
      }
    }

    // If still empty and no network, attempt cache
    if (allPlaces.isEmpty) {
      _loadCachedPlaces();
      if (_nearbyPlaces.isEmpty) {
        setState(() => _hasNetworkError = true);
      }
    } else {
      // Sort by closest distance
      allPlaces.sort((a, b) {
        final da = (a['distance_m'] as num?) ?? 999999;
        final db = (b['distance_m'] as num?) ?? 999999;
        return da.compareTo(db);
      });

      // Save to local cache
      try {
        StorageService.saveStringSync('cached_nearby_$_selectedCategory', jsonEncode(allPlaces));
      } catch (_) {}

      if (mounted) {
        setState(() {
          _nearbyPlaces = allPlaces;
          _isOfflineCache = false;
          _hasNetworkError = false;
        });
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _filteredPlaces {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return _nearbyPlaces;

    return _nearbyPlaces.where((loc) {
      final name = loc['name']?.toString().toLowerCase() ?? '';
      final address = loc['address']?.toString().toLowerCase() ?? '';
      final category = loc['category']?.toString().toLowerCase() ?? '';
      final badge = loc['stock_badge']?.toString().toLowerCase() ?? '';

      return name.contains(query) ||
          address.contains(query) ||
          category.contains(query) ||
          badge.contains(query);
    }).toList();
  }

  Future<void> _openDirections(Map<String, dynamic> loc) async {
    final lat = loc['lat'];
    final lng = loc['lng'];
    final name = (loc['name'] ?? 'Healthcare Facility').toString();
    final address = (loc['address'] ?? '').toString();

    Uri? primaryUri;
    Uri? fallbackUri;

    final hasCoordinates = lat is num && lng is num && lat != 0 && lng != 0;

    if (hasCoordinates) {
      final originParam = _currentPosition != null
          ? '&origin=${_currentPosition!.latitude},${_currentPosition!.longitude}'
          : '';
      final appleOriginParam = _currentPosition != null
          ? '&saddr=${_currentPosition!.latitude},${_currentPosition!.longitude}'
          : '';

      // Standard Google Maps Directions URL (Clean, valid URL without invalid place ID params)
      fallbackUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng$originParam',
      );

      // On iOS, Apple Maps provides native map opening on simulator and physical devices
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        primaryUri = Uri.parse(
          'https://maps.apple.com/?daddr=$lat,$lng$appleOriginParam&dirflg=d&q=${Uri.encodeComponent(name)}',
        );
      } else {
        primaryUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(name)})');
      }
    } else {
      // Coordinate-free address fallback
      final destinationText = address.isNotEmpty ? '$name, $address' : name;
      if (destinationText.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No location details available for this facility.')),
        );
        return;
      }

      fallbackUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(destinationText)}',
      );

      if (Theme.of(context).platform == TargetPlatform.iOS) {
        primaryUri = Uri.parse(
          'https://maps.apple.com/?daddr=${Uri.encodeComponent(destinationText)}',
        );
      }
    }

    try {
      bool launched = false;
      if (primaryUri != null && await canLaunchUrl(primaryUri)) {
        launched = await launchUrl(primaryUri, mode: LaunchMode.externalApplication);
      }
      if (!launched) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching directions: $e');
      try {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        return;
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open map navigation.')),
      );
    }
  }

  Future<void> _callPlace(Map<String, dynamic> loc) async {
    final facilityName = (loc['name'] ?? 'Healthcare Facility').toString();
    final rawPhone = (loc['phone'] ?? '').toString().trim();
    final cleanPhone = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');

    debugPrint('[NearbyHealthcare] Call tapped for: "$facilityName", Phone: "$rawPhone", Clean: "$cleanPhone"');

    if (cleanPhone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available for this facility.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final telUri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      final canLaunch = await canLaunchUrl(telUri);
      if (canLaunch) {
        await launchUrl(telUri);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open phone dialer.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('[NearbyHealthcare] Dialer error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open phone dialer.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final places = _filteredPlaces;

    return Scaffold(
      drawer: const UserSidebar(),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF1E293B)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Nearby Healthcare',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Medicine availability',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.medicineAvailability),
            icon: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
          ),
          IconButton(
            tooltip: 'Refresh location & places',
            onPressed: _isLoading ? null : _initLocationAndFetch,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.my_location, color: AppColors.primary),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search nearby healthcare...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('Hospitals', Icons.local_hospital),
                const SizedBox(width: 10),
                _buildFilterChip('Clinics', Icons.medical_services),
                const SizedBox(width: 10),
                _buildFilterChip('Medical Stores', Icons.medication),
                const SizedBox(width: 10),
                _buildFilterChip('Laboratories', Icons.science),
              ],
            ),
          ),

          // Offline / Cache banner
          if (_isOfflineCache)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_off, size: 16, color: Colors.amber.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Offline Mode — Showing saved nearby facilities',
                      style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

          // Main Content States
          Expanded(child: _buildBody(places)),
        ],
      ),
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> places) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Finding nearby $_selectedCategory...',
              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    // Location Error State
    if (_locationErrorType != null && _nearbyPlaces.isEmpty) {
      return _buildLocationErrorWidget();
    }

    // Network / API Error State
    if (_hasNetworkError && _nearbyPlaces.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 54, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No internet connection',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nearby healthcare data could not be refreshed. Please check your connection.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _initLocationAndFetch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    // Empty Results State
    if (places.isEmpty) {
      final isSearching = _searchController.text.isNotEmpty;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSearching ? Icons.search_off : Icons.local_hospital_outlined,
                size: 54,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                isSearching
                    ? 'No results matching "${_searchController.text}"'
                    : 'No $_selectedCategory found nearby.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              Text(
                isSearching
                    ? 'Try searching with a different term or category.'
                    : 'Try selecting another category or refreshing your location.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // Result Cards List
    return RefreshIndicator(
      onRefresh: _fetchPlaces,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: places.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final loc = places[index];
          return _buildPlaceCard(loc);
        },
      ),
    );
  }

  Widget _buildPlaceCard(Map<String, dynamic> loc) {
    final badge = loc['stock_badge']?.toString();
    final isVitalReach = loc['vitalreach'] == true;

    IconData getLeadingIcon() {
      if (_selectedCategory == 'Hospitals') return Icons.local_hospital;
      if (_selectedCategory == 'Clinics') return Icons.medical_services;
      if (_selectedCategory == 'Medical Stores') return Icons.medication;
      return Icons.science;
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: () => _openDirections(loc),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isVitalReach
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isVitalReach
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  getLeadingIcon(),
                  color: isVitalReach ? AppColors.primary : const Color(0xFF64748B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            loc['name']?.toString() ?? 'Healthcare Facility',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            loc['distance']?.toString() ?? '',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            loc['address']?.toString() ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    if (badge != null && badge.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badge.contains('Low') || badge.contains('Out')
                              ? Colors.orange.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: badge.contains('Low') || badge.contains('Out')
                                ? Colors.orange.shade300
                                : Colors.green.shade300,
                          ),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: badge.contains('Low') || badge.contains('Out')
                                ? Colors.orange.shade800
                                : Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _openDirections(loc),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.directions_outlined, size: 16),
                          label: const Text('Directions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _callPlace(loc),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.phone_outlined, size: 16),
                          label: const Text('Call', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationErrorWidget() {
    IconData icon = Icons.location_off_outlined;
    String title = 'Location Unavailable';
    String message = _locationErrorMessage ?? 'Please enable location to find nearby healthcare.';
    String buttonText = 'Enable Location';
    VoidCallback onAction = () => Geolocator.openLocationSettings();

    if (_locationErrorType == 'permission_denied' || _locationErrorType == 'permission_denied_forever') {
      title = 'Location Permission Required';
      buttonText = 'Open Settings';
      onAction = () => Geolocator.openAppSettings();
    } else if (_locationErrorType == 'service_disabled') {
      title = 'Location Services Disabled';
      buttonText = 'Turn On Location';
      onAction = () => Geolocator.openLocationSettings();
    } else {
      buttonText = 'Retry';
      onAction = _initLocationAndFetch;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 54, color: Colors.orange.shade700),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                onAction();
                await Future.delayed(const Duration(seconds: 1));
                _initLocationAndFetch();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.settings, size: 18),
              label: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () async {
        if (_selectedCategory == label && !_hasNetworkError) return;
        setState(() {
          _selectedCategory = label;
          _isLoading = true;
          _hasNetworkError = false;
        });
        await _fetchPlaces();
        if (mounted) setState(() => _isLoading = false);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
