import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../models/nearby_place.dart';
import '../services/nearby_places_service.dart';
import '../widgets/user_sidebar.dart';

class NearbyHealthcareScreen extends StatefulWidget {
  const NearbyHealthcareScreen({super.key});

  @override
  State<NearbyHealthcareScreen> createState() => _NearbyHealthcareScreenState();
}

class _NearbyHealthcareScreenState extends State<NearbyHealthcareScreen> {
  static const _categories = [
    ('All', Icons.health_and_safety_outlined),
    ('Hospitals', Icons.local_hospital),
    ('Clinics', Icons.medical_services),
    ('Labs', Icons.science),
    ('Pharmacies', Icons.medication),
  ];

  final NearbyPlacesService _service = NearbyPlacesService();
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;

  String _selectedCategory = 'All';
  List<NearbyPlace> _allPlaces = [];
  Position? _currentPosition;
  NearbyLoadState _state = NearbyLoadState.loading;
  String? _errorMessage;
  bool _offlineBanner = false;

  @override
  void initState() {
    super.initState();
    _initLocationAndFetch(forceRefresh: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initLocationAndFetch({bool forceRefresh = false}) async {
    setState(() {
      _state = NearbyLoadState.loading;
      _errorMessage = null;
      _offlineBanner = false;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _state = NearbyLoadState.locationDisabled;
          _errorMessage =
              'Location services are turned off. Enable GPS to find nearby healthcare.';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        setState(() {
          _state = NearbyLoadState.permissionDenied;
          _errorMessage =
              'Location permission is required to find hospitals, clinics, labs, and pharmacies near you.';
        });
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _state = NearbyLoadState.permissionDenied;
          _errorMessage =
              'Location permission is permanently denied. Open settings to enable it.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 25),
        ),
      );
      if (!mounted) return;
      setState(() => _currentPosition = position);
      _animateToUser(position);

      final result = await _service.fetchNearby(
        lat: position.latitude,
        lng: position.longitude,
        forceRefresh: forceRefresh,
        position: position,
      );
      if (!mounted) return;

      setState(() {
        _allPlaces = result.places;
        _state = result.state;
        _errorMessage = result.error;
        _offlineBanner = result.offline || result.state == NearbyLoadState.offlineCached;
      });
      _fitMapToResults(position, result.places);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = NearbyLoadState.locationUnavailable;
        _errorMessage =
            'Could not get your current location. Check GPS signal and try again.';
      });
    }
  }

  void _animateToUser(Position position) {
    if (_mapController == null) return;
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        13.5,
      ),
    );
  }

  bool _looksLikeEmulatorDefault(Position p) {
    // Classic Android emulator default near Googleplex, Mountain View.
    return (p.latitude - 37.421998).abs() < 0.02 &&
        (p.longitude + 122.084).abs() < 0.02;
  }

  void _fitMapToResults(Position user, List<NearbyPlace> places) {
    if (_mapController == null) return;
    if (places.isEmpty) {
      _animateToUser(user);
      return;
    }
    var minLat = user.latitude;
    var maxLat = user.latitude;
    var minLng = user.longitude;
    var maxLng = user.longitude;
    for (final p in places.take(12)) {
      minLat = minLat < p.lat ? minLat : p.lat;
      maxLat = maxLat > p.lat ? maxLat : p.lat;
      minLng = minLng < p.lng ? minLng : p.lng;
      maxLng = maxLng > p.lng ? maxLng : p.lng;
    }
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        56,
      ),
    );
  }

  List<NearbyPlace> get _visiblePlaces {
    var list = _service.filterByCategory(_allPlaces, _selectedCategory);
    final query = _searchController.text.toLowerCase().trim();
    if (query.isNotEmpty) {
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(query) ||
              p.address.toLowerCase().contains(query) ||
              p.categoryLabel.toLowerCase().contains(query))
          .toList();
    }
    return list;
  }

  Set<Marker> get _markers {
    final places = _visiblePlaces;
    final markers = <Marker>{};
    for (var i = 0; i < places.length; i++) {
      final p = places[i];
      markers.add(
        Marker(
          markerId: MarkerId(p.id.isNotEmpty ? p.id : 'p$i'),
          position: LatLng(p.lat, p.lng),
          infoWindow: InfoWindow(
            title: p.name,
            snippet: '${p.categoryLabel} · ${p.distanceLabel}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(_hueForCategory(p.category)),
        ),
      );
    }
    return markers;
  }

  double _hueForCategory(String category) {
    switch (category) {
      case 'hospitals':
        return BitmapDescriptor.hueRed;
      case 'clinics':
        return BitmapDescriptor.hueAzure;
      case 'labs':
        return BitmapDescriptor.hueViolet;
      case 'pharmacies':
        return BitmapDescriptor.hueGreen;
      default:
        return BitmapDescriptor.hueOrange;
    }
  }

  Future<void> _openDirections(NearbyPlace place) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${place.lat},${place.lng}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _callPlace(NearbyPlace place) async {
    final phone = place.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number listed for this place')),
      );
      return;
    }
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<void> _openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  @override
  Widget build(BuildContext context) {
    final places = _visiblePlaces;
    final showMap = _currentPosition != null &&
        _state != NearbyLoadState.permissionDenied &&
        _state != NearbyLoadState.locationDisabled &&
        _state != NearbyLoadState.locationUnavailable;

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
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.medicineAvailability),
            icon: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
          ),
          IconButton(
            tooltip: 'Recenter / Search Nearby',
            onPressed: () => _initLocationAndFetch(forceRefresh: true),
            icon: const Icon(Icons.my_location, color: AppColors.primary),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search nearby healthcare...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                for (var i = 0; i < _categories.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  _buildFilterChip(_categories[i].$1, _categories[i].$2),
                ],
              ],
            ),
          ),
          if (_offlineBanner)
            Material(
              color: const Color(0xFFFFF7ED),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off_outlined, size: 18, color: Colors.orange.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Offline — showing saved nearby results',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_currentPosition != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.my_location, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Searching near ${_currentPosition!.latitude.toStringAsFixed(4)}, '
                      '${_currentPosition!.longitude.toStringAsFixed(4)}'
                      '${_looksLikeEmulatorDefault(_currentPosition!) ? ' (emulator default — set a real GPS)' : ''}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (showMap)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.32,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        zoom: 13.5,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      markers: _markers,
                      onMapCreated: (controller) {
                        _mapController = controller;
                        if (_currentPosition != null) {
                          _animateToUser(_currentPosition!);
                        }
                      },
                    ),
                    if (_state == NearbyLoadState.loading)
                      const Positioned.fill(
                        child: ColoredBox(
                          color: Color(0x66FFFFFF),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Expanded(child: _buildListArea(places)),
        ],
      ),
    );
  }

  Widget _buildListArea(List<NearbyPlace> places) {
    if (_state == NearbyLoadState.loading && _allPlaces.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_state == NearbyLoadState.permissionDenied ||
        _state == NearbyLoadState.locationDisabled ||
        _state == NearbyLoadState.locationUnavailable) {
      return _buildErrorState(
        icon: _state == NearbyLoadState.locationDisabled
            ? Icons.location_disabled
            : Icons.location_off,
        message: _errorMessage ?? 'Location unavailable',
        primaryLabel: _state == NearbyLoadState.locationDisabled
            ? 'Enable location'
            : 'Open settings',
        onPrimary: _state == NearbyLoadState.locationDisabled
            ? _openLocationSettings
            : _openAppSettings,
        secondaryLabel: 'Try again',
        onSecondary: () => _initLocationAndFetch(forceRefresh: true),
      );
    }

    if (_state == NearbyLoadState.networkError ||
        _state == NearbyLoadState.apiError) {
      return _buildErrorState(
        icon: Icons.wifi_off,
        message: _errorMessage ??
            (_state == NearbyLoadState.networkError
                ? 'Network error. Check your connection and try again.'
                : 'Could not load nearby places from the server.'),
        primaryLabel: 'Retry',
        onPrimary: () => _initLocationAndFetch(forceRefresh: true),
      );
    }

    if (places.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No places found nearby. Try another category or expand your search.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: places.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _PlaceCard(
        place: places[index],
        onDirections: () => _openDirections(places[index]),
        onCall: () => _callPlace(places[index]),
        onTap: () {
          final p = places[index];
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(p.lat, p.lng), 15),
          );
        },
      ),
    );
  }

  Widget _buildErrorState({
    required IconData icon,
    required String message,
    required String primaryLabel,
    required VoidCallback onPrimary,
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onPrimary,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(primaryLabel),
            ),
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onSecondary, child: Text(secondaryLabel)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.place,
    required this.onDirections,
    required this.onCall,
    required this.onTap,
  });

  final NearbyPlace place;
  final VoidCallback onDirections;
  final VoidCallback onCall;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${place.categoryLabel} · ${place.distanceLabel}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Directions',
                    onPressed: onDirections,
                    icon: const Icon(Icons.directions_outlined, color: AppColors.primary),
                  ),
                  if (place.phone.isNotEmpty)
                    IconButton(
                      tooltip: 'Call',
                      onPressed: onCall,
                      icon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                    ),
                ],
              ),
              if (place.address.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  place.address,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (place.openNow != null)
                    _chip(
                      place.openNow! ? 'Open now' : 'Closed',
                      place.openNow! ? Colors.green.shade700 : Colors.red.shade700,
                      place.openNow! ? Colors.green.shade50 : Colors.red.shade50,
                    ),
                  if (place.rating != null)
                    _chip(
                      '★ ${place.rating!.toStringAsFixed(1)}'
                      '${place.userRatingCount != null ? ' (${place.userRatingCount})' : ''}',
                      Colors.amber.shade900,
                      Colors.amber.shade50,
                    ),
                  if (place.stockBadge != null && place.stockBadge!.isNotEmpty)
                    _chip(
                      place.stockBadge!,
                      place.stockBadge!.contains('Low') ||
                              place.stockBadge!.contains('Out')
                          ? Colors.orange.shade800
                          : Colors.green.shade700,
                      place.stockBadge!.contains('Low') ||
                              place.stockBadge!.contains('Out')
                          ? Colors.orange.shade50
                          : Colors.green.shade50,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
