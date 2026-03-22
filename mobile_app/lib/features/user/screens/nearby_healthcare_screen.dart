import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:hs053/core/theme/app_colors.dart';
import '../widgets/user_sidebar.dart';

class NearbyHealthcareScreen extends StatefulWidget {
  const NearbyHealthcareScreen({super.key});

  @override
  State<NearbyHealthcareScreen> createState() => _NearbyHealthcareScreenState();
}

class _NearbyHealthcareScreenState extends State<NearbyHealthcareScreen> {
  GoogleMapController? _mapController;
  String _selectedCategory = 'Hospitals';
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _nearbyPlaces = [];
  Map<String, dynamic>? _selectedLocation;
  Set<Marker> _markers = {};
  Position? _currentPosition;
  bool _isLoading = false;
  MapType _currentMapType = MapType.normal;

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

  Future<void> _initLocationAndFetch() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });

      // Move camera to user location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          14.0,
        ),
      );

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

  Future<void> _fetchPlaces() async {
    if (_currentPosition == null) return;

    final amenity = _categoryToAmenity[_selectedCategory] ?? 'hospital';
    final query = _selectedCategory == 'Clinics' 
        ? '["amenity"~"clinic|doctors"]' 
        : '["amenity"="$amenity"]';

    final url = 'https://overpass-api.de/api/interpreter?data=[out:json];node(around:5000,${_currentPosition!.latitude},${_currentPosition!.longitude})$query;out;';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List nodes = data['elements'];

        setState(() {
          _nearbyPlaces = nodes.map((node) {
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
              'name': node['tags']['name'] ?? 'Unnamed ${_selectedCategory.substring(0, _selectedCategory.length - 1)}',
              'category': _selectedCategory,
              'rating': 4.0 + (node['id'] % 10) / 10, // Mock rating based on ID
              'distance': '${(distanceInMeters / 1000).toStringAsFixed(1)} km away',
              'address': node['tags']['addr:street'] ?? 'Nearby ${_currentPosition!.latitude.toStringAsFixed(2)}, ${_currentPosition!.longitude.toStringAsFixed(2)}',
              'position': LatLng(lat, lon),
              'isOpen247': node['tags']['opening_hours'] == '24/7',
            };
          }).toList();
          
          _updateMarkers();
        });
      }
    } catch (e) {
      print('Error fetching places: $e');
    }
  }

  void _updateMarkers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _markers = _nearbyPlaces
          .where((loc) => 
              (query.isEmpty || 
               loc['name'].toLowerCase().contains(query) || 
               loc['address'].toLowerCase().contains(query)))
          .map((loc) {
        return Marker(
          markerId: MarkerId(loc['id']),
          position: loc['position'],
          icon: BitmapDescriptor.defaultMarkerWithHue(_getHue(loc['category'])),
          onTap: () {
            setState(() {
              _selectedLocation = loc;
            });
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(loc['position']),
            );
          },
        );
      }).toSet();
    });
  }

  double _getHue(String category) {
    switch (category) {
      case 'Clinics':
        return BitmapDescriptor.hueGreen;
      case 'Medical Stores':
        return BitmapDescriptor.hueAzure;
      case 'Laboratories':
        return BitmapDescriptor.hueViolet;
      default:
        return BitmapDescriptor.hueBlue;
    }
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal 
          ? MapType.satellite 
          : MapType.normal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const UserSidebar(),
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
      ),
      body: Stack(
        children: [
          // Map Background
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null 
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : const LatLng(28.6139, 77.2090),
              zoom: 14,
            ),
            mapType: _currentMapType,
            onMapCreated: (controller) {
              _mapController = controller;
              if (_currentPosition != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLng(LatLng(_currentPosition!.latitude, _currentPosition!.longitude)),
                );
              }
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onTap: (_) {
              setState(() {
                _selectedLocation = null;
              });
            },
          ),

          if (_isLoading)
            const Center(child: CircularProgressIndicator()),

          // Search Bar
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  _updateMarkers();
                },
                decoration: const InputDecoration(
                  hintText: 'Search nearby healthcare...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: AppColors.primary),
                ),
              ),
            ),
          ),

          // Category Filters
          Positioned(
            top: 90,
            left: 0,
            right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
          ),

          // Map Action Buttons (Right Side)
          Positioned(
            right: 20,
            top: 160,
            child: Column(
              children: [
                _buildMapActionButton(Icons.my_location, _initLocationAndFetch),
                const SizedBox(height: 12),
                _buildMapActionButton(Icons.layers_outlined, _toggleMapType),
              ],
            ),
          ),

          // Info Card
          if (_selectedLocation != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildLocationCard(),
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
          _selectedLocation = null;
          _isLoading = true;
        });
        await _fetchPlaces();
        setState(() => _isLoading = false);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppColors.primary,
            width: 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
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

  Widget _buildMapActionButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedLocation?['isOpen247'] ?? false)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFFFFA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('OPEN 24/7', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedLocation?['name'] ?? '',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 16),
                        const SizedBox(width: 4),
                        Text('${_selectedLocation?['rating'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 12),
                        const Icon(Icons.location_on, color: Colors.grey, size: 16),
                        const SizedBox(width: 4),
                        Text(_selectedLocation?['distance'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.business, color: AppColors.primary, size: 30),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(_selectedLocation?['address'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.directions_outlined, size: 18),
                  label: const Text('Directions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone_outlined, size: 18),
                  label: const Text('Call Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightBlue,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
