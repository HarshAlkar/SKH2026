import 'package:flutter/material.dart';
import 'package:hs053/core/widgets/common_appbar.dart';
import 'package:hs053/features/asha_worker/widgets/asha_drawer.dart';
import 'package:hs053/core/routes/app_routes.dart';
import 'package:hs053/shared/models/patient_model.dart';
import 'package:hs053/shared/models/health_record_model.dart';
import 'package:hs053/core/services/api_service.dart';
import 'package:hs053/core/constants/api_constants.dart';

class PatientDetailsScreen extends StatefulWidget {
  const PatientDetailsScreen({super.key});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  final ApiService _apiService = ApiService();
  PatientModel? _patient;
  HealthRecordModel? _latestRecord;
  bool _isLoading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_patient == null) {
      _initialize();
    }
  }

  Future<void> _initialize() async {
    try {
      final args = ModalRoute.of(context)?.settings.arguments;
      
      if (args is PatientModel) {
        _patient = args;
        await _fetchLatestRecord();
      } else if (args is Map) {
        final id = args['id']?.toString();
        if (id != null) {
          await _fetchPatientAndRecords(id);
        } else {
          setState(() => _isLoading = false);
        }
      } else {
         setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Init error: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchPatientAndRecords(String id) async {
    try {
      final pResponse = await _apiService.get('${ApiConstants.patientsEndpoint}$id/');
      _patient = PatientModel.fromJson(pResponse);
      await _fetchLatestRecord();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchLatestRecord() async {
    if (_patient == null) return;

    try {
      final response = await _apiService.get('${ApiConstants.recordsEndpoint}?patient_id=${_patient!.id}');
      final List<HealthRecordModel> records = (response as List)
          .map((data) => HealthRecordModel.fromJson(data))
          .toList();

      if (mounted) {
        setState(() {
          if (records.isNotEmpty) {
            _latestRecord = records.first;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: CommonAppBar(title: 'Loading...'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: const CommonAppBar(title: 'Error'),
        body: Center(child: Text("Error: $_error")),
      );
    }

    if (_patient == null) {
      return Scaffold(
        appBar: const CommonAppBar(title: 'Patient Details'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Patient data not found"),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Go Back"))
            ],
          ),
        ),
      );
    }

    const Color primaryColor = Color(0xFF2F4DB6);
    const Color backgroundColor = Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: CommonAppBar(
        title: 'Patient Details',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context, 
                AppRoutes.editPatient, 
                arguments: _patient
              );
              if (result == true) {
                setState(() => _isLoading = true);
                _initialize();
              }
            },
          ),
        ],
      ),
      drawer: const AshaDrawer(currentRoute: ''),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2F4DB6), Color(0xFF4A90E2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, size: 48, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _patient!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Patient ID: #ASC-100${_patient!.id}",
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildHeaderStat("AGE", _patient!.age.toString()),
                        _buildHeaderStat("GENDER", _patient!.gender),
                        _buildHeaderStat("BLOOD", _patient!.bloodGroup),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Basic Info Section
              _buildSectionTitle("BASIC INFORMATION"),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.location_on_outlined, "Address", _patient!.address.isNotEmpty ? _patient!.address : "Village: ${_patient!.village}"),
                    _buildInfoRow(Icons.phone_outlined, "Contact", _patient!.phoneNumber),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Health Vitals Section
              _buildSectionTitle("LAST REPORTED VITALS (${_latestRecord?.lastUpdated ?? 'N/A'})"),
              _latestRecord == null 
                  ? Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: const Center(child: Text("No records found", style: TextStyle(color: Colors.grey))),
                    )
                  : Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildVitalsCard("B.P", _latestRecord!.bloodPressure, Icons.monitor_heart, Colors.red)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildVitalsCard("Sugar", _latestRecord!.bloodSugar, Icons.air, Colors.blue)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildVitalsCard("TEMP", _latestRecord!.temperature, Icons.thermostat, Colors.orange)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildVitalsCard("WEIGHT", _latestRecord!.weight, Icons.scale, Colors.green)),
                          ],
                        ),
                      ],
                    ),

              const SizedBox(height: 32),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.updateHealth, arguments: _patient!.name);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("UPDATE HEALTH", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[300], size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
