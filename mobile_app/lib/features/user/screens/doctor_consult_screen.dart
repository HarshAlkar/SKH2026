import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/user_sidebar.dart';

class DoctorConsultScreen extends StatefulWidget {
  const DoctorConsultScreen({super.key});

  @override
  State<DoctorConsultScreen> createState() => _DoctorConsultScreenState();
}

class _DoctorConsultScreenState extends State<DoctorConsultScreen> {
  String _selectedSpecialty = 'All Doctors';
  final TextEditingController _searchController = TextEditingController();
  
  final List<String> _specialties = [
    'All Doctors',
    'Physician',
    'Cardiology',
    'Pediatrics',
    'Dermatology',
    'Neurology'
  ];

  final List<Map<String, dynamic>> _doctors = [
    {
      'name': 'Dr. Aryan Sharma',
      'specialty': 'Senior Cardiologist',
      'experience': '12 Years Experience',
      'reviews': '2.5k Reviews',
      'rating': 4.9,
      'image': 'https://i.pravatar.cc/150?u=1',
      'isOnline': true,
    },
    {
      'name': 'Dr. Priya Verma',
      'specialty': 'Physician',
      'experience': '8 Years Experience',
      'reviews': '1.2k Reviews',
      'rating': 4.7,
      'image': 'https://i.pravatar.cc/150?u=2',
      'isOnline': true,
    },
    {
      'name': 'Dr. Rohan Gupta',
      'specialty': 'Pediatrics',
      'experience': '10 Years Experience',
      'reviews': '900 Reviews',
      'rating': 4.8,
      'image': 'https://i.pravatar.cc/150?u=3',
      'isOnline': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const UserSidebar(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.primary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Column(
          children: [
            const Text(
              'Consult a Doctor',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Gramin Health Connect',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.primary),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Network Optimization Card
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.wifi, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Network Optimization',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'If internet is slow, the system will switch to audio or chat.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search doctors, specialties...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Specialty Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: _specialties.map((specialty) {
                  final isSelected = _selectedSpecialty == specialty;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(specialty),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedSpecialty = specialty;
                        });
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Doctor List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: _doctors
                    .where((doc) =>
                        (_selectedSpecialty == 'All Doctors' ||
                            doc['specialty'].toString().contains(_selectedSpecialty)) &&
                        (doc['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase())))
                    .map((doctor) => _buildDoctorCard(doctor))
                    .toList(),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: NetworkImage(doctor['image']),
                    backgroundColor: AppColors.lightBlue,
                  ),
                  if (doctor['isOnline'])
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor['specialty'],
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.history, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          doctor['experience'],
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${doctor['rating']} (${doctor['reviews']})',
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildIconButton(Icons.videocam_outlined, AppColors.primary, () {}),
              const SizedBox(width: 12),
              _buildIconButton(Icons.phone_outlined, Colors.green, () {}),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
          color: color.withOpacity(0.05),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
