import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/patient_model.dart';
import '../widgets/patient_card.dart';
import '../widgets/add_patient_button.dart';
import '../../asha_worker/widgets/asha_sidebar.dart';
import '../../../core/sync/offline_api.dart';
import '../../../providers/auth_provider.dart';

class VillagePatientsScreen extends StatefulWidget {
  final bool embedded;
  const VillagePatientsScreen({super.key, this.embedded = false});

  @override
  State<VillagePatientsScreen> createState() => _VillagePatientsScreenState();
}

class _VillagePatientsScreenState extends State<VillagePatientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final OfflineApi _api = OfflineApi.instance;

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

  Future<void> _fetchPatients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final raw = await _api.get('/users/patients/');
      final List<dynamic> data = raw is List ? raw : <dynamic>[];
      if (!mounted) return;
      setState(() {
        _allPatients = data.map((json) {
          final details = json['profile_details'] is Map
              ? Map<String, dynamic>.from(json['profile_details'] as Map)
              : <String, dynamic>{};
          return PatientModel(
            id: json['id'].toString(),
            userId: json['id'] is int
                ? json['id'] as int
                : int.tryParse(json['id']?.toString() ?? ''),
            patientId: details['patient_id'] is int
                ? details['patient_id'] as int
                : int.tryParse(details['patient_id']?.toString() ?? ''),
            name: json['name'] ?? 'Unknown',
            age: int.tryParse(details['age']?.toString() ?? '') ?? 0,
            village: json['village'] ?? 'Unknown',
            status: 'Active',
            gender: details['gender']?.toString() ?? '',
            bloodGroup: details['blood_group']?.toString() ?? '',
            address: details['address']?.toString() ?? '',
            phoneNumber: json['phone_number']?.toString() ?? '',
          );
        }).toList();
        _filteredPatients = _allPatients;
        _isLoading = false;
        _error = null;
      });
      _filterPatients(_searchController.text);
    } catch (e) {
      debugPrint('Error fetching patients: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error =
            'Could not load patients. Check your connection and try again.';
      });
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

  Widget _buildListBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchPatients,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredPatients.isEmpty) {
      return const Center(child: Text('No patients found'));
    }

    return RefreshIndicator(
      onRefresh: _fetchPatients,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredPatients.length,
        itemBuilder: (context, index) {
          return PatientCard(patient: _filteredPatients[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isAsha = auth.user?.role == 'asha_worker';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: isAsha && !widget.embedded ? const AshaSidebar() : null,
      appBar: AppBar(
        title: Text(
          'Village Patients',
          style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: darkBlue),
        automaticallyImplyLeading: !widget.embedded,
        leading: isAsha && !widget.embedded
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : null,
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
                            prefixIcon:
                                Icon(Icons.search, color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: primaryColor, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      AddPatientButton(onPatientAdded: _fetchPatients),
                    ],
                  ),
                ),
                Expanded(child: _buildListBody()),
              ],
            ),
    );
  }
}
