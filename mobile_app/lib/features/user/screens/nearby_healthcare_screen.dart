import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';
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
  
  // Mock data for locations
  final List<Map<String, dynamic>> _allLocations = [
    {
      'id': '1',
      'name': 'City General Hospital',
      'category': 'Hospitals',
      'rating': 4.8,
      'distance': '0.8 km away',
      'address': 'Sector 14, Main Road',
      'position': const LatLng(28.6139, 77.2090),
      'isOpen247': true,
    },
    {
      'id': '2',
      'name': 'Apollo Clinic',
      'category': 'Clinics',
      'rating': 4.5,
      'distance': '1.2 km away',
      'address': 'Block B, Connaught Place',
      'position': const LatLng(28.6280, 77.2180),
      'isOpen247': false,
    },
    {
      'id': '3',
      'name': 'MediCare Store',
      'category': 'Medical Stores',
      'rating': 4.2,
      'distance': '0.5 km away',
      'address': 'Market Yard, Gate 2',
      'position': const LatLng(28.6100, 77.2000),
      'isOpen247': true,
    },
  ];

  Map<String, dynamic>? _selectedLocation;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _updateMarkers();
  }

  void _updateMarkers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _markers = _allLocations
          .where((loc) => 
              loc['category'] == _selectedCategory && 
              (query.isEmpty || loc['name'].toLowerCase().contains(query) || loc['address'].toLowerCase().contains(query)))
          .map((loc) {

        return Marker(
          markerId: MarkerId(loc['id']),
          position: loc['position'],
          icon: BitmapDescriptor.defaultMarkerWithHue(_getHue(loc['category'])),
          onTap: () {
            setState(() {
              _selectedLocation = loc;
            });
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
      default:
        return BitmapDescriptor.hueBlue;
    }
  }

  Future<void> _currentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 15,
        ),
      ),
    );
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
            initialCameraPosition: const CameraPosition(
              target: LatLng(28.6139, 77.2090),
              zoom: 13,
            ),
            onMapCreated: (controller) => _mapController = controller,
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
                  setState(() {
                    _updateMarkers();
                  });
                },
                decoration: const InputDecoration(

                  hintText: 'Search hospitals, doctors...',
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
                _buildMapActionButton(Icons.my_location, _currentLocation),
                const SizedBox(height: 12),
                _buildMapActionButton(Icons.layers_outlined, () {}),
              ],
            ),
          ),

          // Hospital Info Card
          if (_selectedLocation != null)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
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
      onTap: () {
        setState(() {
          _selectedCategory = label;
          _selectedLocation = null;
        });
        _updateMarkers();
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
      padding: const EdgeInsets.all(24),
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
                        child: const Text(
                          'OPEN 24/7',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedLocation?['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${_selectedLocation?['rating'] ?? ''}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.location_on, color: Colors.grey, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _selectedLocation?['distance'] ?? '',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                   width: 80,
                   height: 80,
                   color: AppColors.lightBlue,
                   child: const Icon(Icons.business, color: AppColors.primary, size: 40),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _selectedLocation?['address'] ?? '',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
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
