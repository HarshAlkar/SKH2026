import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../chat/widgets/contact_action_row.dart';
import 'patient_details_screen.dart';

class MyPatientsScreen extends StatefulWidget {
  final bool embedded;
  const MyPatientsScreen({super.key, this.embedded = false});

  @override
  State<MyPatientsScreen> createState() => _MyPatientsScreenState();
}

class _MyPatientsScreenState extends State<MyPatientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _api = ApiService();
  String _searchQuery = '';
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;

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
    setState(() => _isLoading = true);
    try {
      final data = await _api.get('/users/patients/');
      setState(() {
        _patients = data is List
            ? List<Map<String, dynamic>>.from(data)
            : [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching patients: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  PatientData _toPatientData(Map<String, dynamic> json) {
    final details = json['profile_details'] is Map
        ? Map<String, dynamic>.from(json['profile_details'] as Map)
        : <String, dynamic>{};
    return PatientData(
      name: json['name']?.toString() ?? 'Patient',
      age: details['age']?.toString() ?? '—',
      gender: details['gender']?.toString() ?? 'Not set',
      village: json['village']?.toString() ?? details['address']?.toString() ?? '—',
      bloodType: details['blood_group']?.toString() ?? 'Not set',
      phoneNumber: json['phone_number']?.toString() ?? '',
      chronicConditions: 'See medical history on file.',
      pastSurgeries: 'Not recorded',
      allergies: 'Not recorded',
      symptoms: const [],
      aiInsights: 'Registered patient. Start a video or audio consultation, or create a prescription.',
      userId: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      patientId: details['patient_id'] is int
          ? details['patient_id'] as int
          : int.tryParse(details['patient_id']?.toString() ?? ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    const lightBg = Color(0xFFF3F4F6);
    const textPrimary = Color(0xFF1F2937);
    final filtered = _patients.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: !widget.embedded,
        leading: widget.embedded
            ? null
            : IconButton(
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
            icon: const Icon(Icons.refresh, color: textPrimary),
            onPressed: _fetchPatients,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text('No patients found'))
                    : RefreshIndicator(
                        onRefresh: _fetchPatients,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final json = filtered[index];
                            final patient = _toPatientData(json);
                            return _buildPatientCard(patient);
                          },
                        ),
                      ),
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

  Widget _buildPatientCard(PatientData patient) {
    const textPrimary = Color(0xFF1F2937);
    const textSecondary = Color(0xFF6B7280);
    final initials = patient.name
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((e) => e[0])
        .take(2)
        .join();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientDetailsScreen(patient: patient),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFFE8F1FF),
                      child: Text(
                        initials.isEmpty ? 'P' : initials,
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
                          if (patient.phoneNumber.isNotEmpty)
                            Text(
                              patient.phoneNumber,
                              style: const TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (patient.userId != null) ...[
                  const SizedBox(height: 12),
                  ContactActionRow(
                    peerName: patient.name,
                    peerUserId: patient.userId!,
                    patientId: patient.patientId ?? patient.userId,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
