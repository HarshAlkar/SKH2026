import 'package:flutter/material.dart';
import 'patient_details_screen.dart';

class Patient {
  final String name;
  final String age;
  final String village;
  final String lastVisit;
  final String status;
  final Color statusColor;

  Patient({
    required this.name,
    required this.age,
    required this.village,
    required this.lastVisit,
    required this.status,
    required this.statusColor,
  });
}

class MyPatientsScreen extends StatefulWidget {
  const MyPatientsScreen({super.key});

  @override
  State<MyPatientsScreen> createState() => _MyPatientsScreenState();
}

class _MyPatientsScreenState extends State<MyPatientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final Map<String, List<Patient>> _groupedPatients = {
    'TODAY': [
      Patient(
        name: 'Sarah Jenkins',
        age: '28',
        village: 'Green Valley',
        lastVisit: 'Today · 09:45 AM',
        status: 'Recovering',
        statusColor: const Color(0xFFF59E0B),
      ),
      Patient(
        name: 'Amitabh Bachchan',
        age: '78',
        village: 'Mumbai South',
        lastVisit: 'Today · 10:30 AM',
        status: 'Needs Consultation',
        statusColor: const Color(0xFFEF4444),
      ),
    ],
    'YESTERDAY': [
      Patient(
        name: 'Ramesh Patil',
        age: '45',
        village: 'Kaman',
        lastVisit: 'Yesterday · 06:20 PM',
        status: 'Recovered',
        statusColor: const Color(0xFF22C55E),
      ),
      Patient(
        name: 'Priyanka Chopra',
        age: '38',
        village: 'Juhu',
        lastVisit: 'Yesterday · 11:15 AM',
        status: 'Recovering',
        statusColor: const Color(0xFFF59E0B),
      ),
    ],
    'THIS WEEK': [
      Patient(
        name: 'Sunita Deshmukh',
        age: '32',
        village: 'Pelhar',
        lastVisit: '3 days ago',
        status: 'Needs Consultation',
        statusColor: const Color(0xFFEF4444),
      ),
      Patient(
        name: 'Rajesh Khanna',
        age: '55',
        village: 'Virar West',
        lastVisit: '4 days ago',
        status: 'Recovered',
        statusColor: const Color(0xFF22C55E),
      ),
    ],
    'THIS MONTH': [
      Patient(
        name: 'Lata Bai',
        age: '62',
        village: 'Vasai',
        lastVisit: '12 days ago',
        status: 'Recovering',
        statusColor: const Color(0xFFF59E0B),
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    const lightBg = Color(0xFFF3F4F6);
    const textPrimary = Color(0xFF1F2937);

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Patients',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: textPrimary),
            onPressed: () {
              // Implementation of search activation could be added here if needed
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(
            child: _buildPatientList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search patient by name...',
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2A7DE1), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientList() {
    List<Widget> listItems = [];

    _groupedPatients.forEach((section, patients) {
      final filteredPatients = patients
          .where((p) => p.name.toLowerCase().contains(_searchQuery))
          .toList();

      if (filteredPatients.isNotEmpty) {
        listItems.add(_buildSectionHeader(section));
        for (var patient in filteredPatients) {
          listItems.add(_buildPatientCard(patient));
        }
        listItems.add(const SizedBox(height: 16));
      }
    });

    if (listItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No patients found',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 8),
        ...listItems,
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildPatientCard(Patient patient) {
    const textPrimary = Color(0xFF1F2937);
    const textSecondary = Color(0xFF6B7280);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            PatientData patientData;
            if (patient.name.contains('Ramesh')) {
              patientData = PatientData.getDummyRamesh();
            } else if (patient.name.contains('Amitabh')) {
              patientData = PatientData.getDummyAmitabh();
            } else if (patient.name.contains('Sunita')) {
              patientData = PatientData.getDummySunita();
            } else {
              patientData = PatientData.getDummySarah();
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientDetailsScreen(patient: patientData),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFE8F1FF),
                  child: Text(
                    patient.name.split(' ').map((e) => e[0]).take(2).join(''),
                    style: const TextStyle(
                      color: Color(0xFF2A7DE1),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Age: ${patient.age} · Village: ${patient.village}',
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last Visit: ${patient.lastVisit}',
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(patient.status, patient.statusColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
