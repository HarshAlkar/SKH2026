import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/patient_model.dart';
import '../widgets/patient_card.dart';
import '../widgets/add_patient_button.dart';
import '../../asha_worker/widgets/asha_sidebar.dart';
import '../../../core/services/api_service.dart';
import '../../../providers/auth_provider.dart';

class VillagePatientsScreen extends StatefulWidget {
  const VillagePatientsScreen({super.key});

  @override
  State<VillagePatientsScreen> createState() => _VillagePatientsScreenState();
}

class _VillagePatientsScreenState extends State<VillagePatientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _api = ApiService();
  
  List<PatientModel> _allPatients = [];
  List<PatientModel> _filteredPatients = [];
  bool _isLoading = true;

  final Color primaryColor = const Color(0xFF2A7DE1);
  final Color darkBlue = const Color(0xFF005BBC);

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    setState(() => _isLoading = true);
    try {
      final List<dynamic> data = await _api.get('/users/patients/');
      setState(() {
        _allPatients = data.map((json) => PatientModel(
          id: json['id'].toString(),
          name: json['name'] ?? 'Unknown',
          age: 0, // Age not in user record directly, maybe in patient profile
          village: json['village'] ?? 'Unknown',
          status: 'Active',
        )).toList();
        _filteredPatients = _allPatients;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching patients: $e');
      setState(() => _isLoading = false);
    }
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
    final auth = Provider.of<AuthProvider>(context);
    final isAsha = auth.user?.role == 'asha_worker';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: isAsha ? const AshaSidebar() : null,
      appBar: AppBar(
        title: Text(
          'Village Patients',
          style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: darkBlue),
        // Remove back arrow if ASHA
        automaticallyImplyLeading: !isAsha,
        leading: isAsha ? Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ) : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: darkBlue,
            onPressed: _fetchPatients,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
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
                          fillColor: Colors.grey[50],
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
                child: _filteredPatients.isEmpty 
                  ? const Center(child: Text("No patients found"))
                  : ListView.builder(
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
