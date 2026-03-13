import 'package:flutter/material.dart';
import '../models/patient_model.dart';
import '../widgets/patient_card.dart';
import '../widgets/add_patient_button.dart';

class VillagePatientsScreen extends StatefulWidget {
  const VillagePatientsScreen({super.key});

  @override
  State<VillagePatientsScreen> createState() => _VillagePatientsScreenState();
}

class _VillagePatientsScreenState extends State<VillagePatientsScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<PatientModel> _allPatients = [
    PatientModel(
      name: 'Ramesh Patil',
      age: 45,
      village: 'Kaman',
      status: 'Stable',
    ),
    PatientModel(
      name: 'Savitri Devi',
      age: 62,
      village: 'Kaman',
      status: 'Stable',
    ),
    PatientModel(
      name: 'Arun Kumar',
      age: 28,
      village: 'Kaman',
      status: 'Checkup Due',
    ),
  ];

  List<PatientModel> _filteredPatients = [];

  final Color primaryColor = const Color(0xFF2A7DE1);
  final Color darkBlue = const Color(0xFF005BBC);

  @override
  void initState() {
    super.initState();
    _filteredPatients = _allPatients;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterPatients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPatients = _allPatients;
      } else {
        _filteredPatients = _allPatients
            .where(
              (patient) =>
                  patient.name.toLowerCase().contains(query.toLowerCase()) ||
                  patient.village.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Village Patients',
          style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: darkBlue),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            color: darkBlue,
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterPatients,
                    decoration: InputDecoration(
                      hintText: 'Search patient...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const AddPatientButton(),
              ],
            ),
          ),
          // Patient List Section
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredPatients.length,
              itemBuilder: (context, index) {
                return PatientCard(patient: _filteredPatients[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
