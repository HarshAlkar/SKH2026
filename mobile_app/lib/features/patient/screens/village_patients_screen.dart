import 'package:flutter/material.dart';
import '../../../core/widgets/common_appbar.dart';
import '../../../routes/app_routes.dart';
import '../../asha_worker/widgets/asha_drawer.dart';
import '../models/patient_model.dart';
import '../widgets/patient_card.dart';
import '../widgets/add_patient_button.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';

class VillagePatientsScreen extends StatefulWidget {
  const VillagePatientsScreen({super.key});

  @override
  State<VillagePatientsScreen> createState() => _VillagePatientsScreenState();
}

class _VillagePatientsScreenState extends State<VillagePatientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  List<PatientModel> _allPatients = [];
  List<PatientModel> _filteredPatients = [];
  bool _isLoading = true;
  String? _error;

  final Color primaryColor = const Color(0xFF2A7DE1);
  final Color darkBlue = const Color(0xFF005BBC);

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPatients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.get(ApiConstants.patientsEndpoint);
      // Backend returns a list of patient dictionaries
      final List<PatientModel> fetched = (response as List)
          .map((data) => PatientModel.fromJson(data))
          .toList();

      setState(() {
        _allPatients = fetched;
        _filteredPatients = _allPatients;
        _isLoading = false;
      });
      _filterPatients(_searchController.text);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
      appBar: const CommonAppBar(
        title: 'Village Patients',
      ),
      drawer: const AshaDrawer(currentRoute: AppRoutes.villagePatients),
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
          
          // Loading / Error / Patient List Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                            const SizedBox(height: 16),
                            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchPatients,
                              child: const Text('Retry'),
                            )
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchPatients,
                        child: _filteredPatients.isEmpty
                          ? ListView(
                              children: const [
                                Padding(
                                  padding: EdgeInsets.all(40.0),
                                  child: Center(
                                    child: Text(
                                      "No patients found in your village.",
                                      style: TextStyle(color: Colors.grey, fontSize: 16),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredPatients.length,
                              itemBuilder: (context, index) {
                                return PatientCard(patient: _filteredPatients[index]);
                              },
                            ),
                      ),
          ),
        ],
      ),
    );
  }
}
