import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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

  final Map<String, String> _categoryToAmenity = {
    'Hospitals': 'hospital',
    'Clinics': 'clinic',
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
    setState(() => _isLoading = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);
      await _fetchPlaces();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchVitalReachFacilities() async {
    if (_currentPosition == null || _selectedCategory != 'Medical Stores') {
      return [];
    }
    try {
      final data = await OfflineApi.instance.get('/stock/map/');
      final list = data is List ? data : <dynamic>[];
      final out = <Map<String, dynamic>>[];
      for (final raw in list) {
        if (raw is! Map) continue;
        final lat = double.tryParse('${raw['lat'] ?? ''}');
        final lng = double.tryParse('${raw['lng'] ?? ''}');
        if (lat == null || lng == null) continue;
        final distanceInMeters = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          lat,
          lng,
        );
        if (distanceInMeters > 25000) continue;
        final low = int.tryParse('${raw['low_stock'] ?? 0}') ?? 0;
        final outStock = int.tryParse('${raw['out_of_stock'] ?? 0}') ?? 0;
        String badge = 'In Stock';
        if (outStock > 0 && low == 0) badge = 'Some Out';
        if (low > 0) badge = 'Low Stock';
        if ((int.tryParse('${raw['total_batches'] ?? 0}') ?? 0) == 0) {
          badge = 'No Stock Data';
        }
        out.add({
          'id': 'vr-${raw['id']}',
          'name': '${raw['label'] ?? 'VitalReach Facility'} (VitalReach)',
          'category': 'Medical Stores',
          'distance': '${(distanceInMeters / 1000).toStringAsFixed(1)} km away',
          'address': '${raw['village'] ?? ''} · Low:$low Out:$outStock · $badge',
          'lat': lat,
          'lng': lng,
          'phone': '',
          'stock_badge': badge,
          'vitalreach': true,
        });
      }
      return out;
    } catch (e) {
      debugPrint('VitalReach facilities: $e');
      return [];
    }
  }

  Future<void> _fetchPlaces() async {
    if (_currentPosition == null) return;

    final amenity = _categoryToAmenity[_selectedCategory] ?? 'hospital';
    final query = _selectedCategory == 'Clinics'
        ? '["amenity"~"clinic|doctors"]'
        : '["amenity"="$amenity"]';

    final url =
        'https://overpass-api.de/api/interpreter?data=[out:json];node(around:5000,${_currentPosition!.latitude},${_currentPosition!.longitude})$query;out;';

    try {
      final response = await http.get(Uri.parse(url));
      final places = <Map<String, dynamic>>[];
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List nodes = data['elements'];

        places.addAll(nodes.map((node) {
          final lat = node['lat'] as double;
          final lon = node['lon'] as double;
          final distanceInMeters = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            lat,
            lon,
          );

          return {
            'id': node['id'].toString(),
            'name': node['tags']['name'] ??
                'Unnamed ${_selectedCategory.substring(0, _selectedCategory.length - 1)}',
            'category': _selectedCategory,
            'distance': '${(distanceInMeters / 1000).toStringAsFixed(1)} km away',
            'address': node['tags']['addr:street'] ??
                'Nearby ${_currentPosition!.latitude.toStringAsFixed(2)}, ${_currentPosition!.longitude.toStringAsFixed(2)}',
            'lat': lat,
            'lng': lon,
            'phone': node['tags']['phone'] ?? node['tags']['contact:phone'] ?? '',
            'vitalreach': false,
          };
        }));
      }

      final vr = await _fetchVitalReachFacilities();
      places.insertAll(0, vr);
      places.sort((a, b) {
        final da = double.tryParse('${a['distance']}'.split(' ').first) ?? 999;
        final db = double.tryParse('${b['distance']}'.split(' ').first) ?? 999;
        return da.compareTo(db);
      });

      setState(() => _nearbyPlaces = places);
    } catch (e) {
      debugPrint('Error fetching places: $e');
      final vr = await _fetchVitalReachFacilities();
      if (vr.isNotEmpty) setState(() => _nearbyPlaces = vr);
    }
  }

  List<Map<String, dynamic>> get _filteredPlaces {
    final query = _searchController.text.toLowerCase().trim();
    return _nearbyPlaces.where((loc) {
      if (query.isEmpty) return true;
      final name = loc['name']?.toString().toLowerCase() ?? '';
      final address = loc['address']?.toString().toLowerCase() ?? '';
      return name.contains(query) || address.contains(query);
    }).toList();
  }

  Future<void> _openDirections(Map<String, dynamic> loc) async {
    final lat = loc['lat'];
    final lng = loc['lng'];
    if (lat is! num || lng is! num) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _callPlace(Map<String, dynamic> loc) async {
    final phone = (loc['phone'] ?? '').toString().replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number listed for this place')),
      );
      return;
    }
    await launchUrl(Uri(scheme: 'tel', path: phone));
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
            tooltip: 'Refresh location',
            onPressed: _initLocationAndFetch,
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
                _buildFilterChip('Hospitals', Icons.local_hospital),
                const SizedBox(width: 12),
                _buildFilterChip('Clinics', Icons.medical_services),
                const SizedBox(width: 12),
                _buildFilterChip('Medical Stores', Icons.medication),
                const SizedBox(width: 12),
                _buildFilterChip('Laboratories', Icons.science),
              ],
            ),
          ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (places.isEmpty)
            const Expanded(
              child: Center(child: Text('No places found nearby. Try another category.')),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: places.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final loc = places[index];
                  final badge = loc['stock_badge']?.toString();
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(
                        loc['name']?.toString() ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${loc['distance'] ?? ''} · ${loc['address'] ?? ''}'),
                          if (badge != null && badge.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                badge,
                                style: TextStyle(
                                  color: badge.contains('Low') || badge.contains('Out')
                                      ? Colors.orange.shade800
                                      : Colors.green.shade700,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      isThreeLine: badge != null,
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'Directions',
                            onPressed: () => _openDirections(loc),
                            icon: const Icon(Icons.directions_outlined, color: AppColors.primary),
                          ),
                          IconButton(
                            tooltip: 'Call',
                            onPressed: () => _callPlace(loc),
                            icon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                          ),
                        ],
                      ),
                      onTap: () => _openDirections(loc),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () async {
        setState(() {
          _selectedCategory = label;
          _isLoading = true;
        });
        await _fetchPlaces();
        if (mounted) setState(() => _isLoading = false);
      },
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
