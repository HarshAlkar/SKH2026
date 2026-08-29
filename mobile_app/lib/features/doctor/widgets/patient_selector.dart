import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class PatientSelector extends StatefulWidget {
  final Function(String) onPatientSelected;

  const PatientSelector({super.key, required this.onPatientSelected});

  @override
  State<PatientSelector> createState() => _PatientSelectorState();
}

class _PatientSelectorState extends State<PatientSelector> {
  final ApiService _api = ApiService();
  String? _selectedPatient;
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    try {
      final data = await _api.get('/users/patients/');
      if (mounted) {
        setState(() {
          _patients = data is List
              ? List<Map<String, dynamic>>.from(data)
              : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Patient",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: _isLoading
                ? const SizedBox(
                    height: 48,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : DropdownButton<String>(
                    value: _selectedPatient,
                    hint: const Text(
                      "Search patient...",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    items: _patients.map((patient) {
                      final name = patient['name']?.toString() ?? 'Patient';
                      final details = patient['profile_details'] is Map
                          ? Map<String, dynamic>.from(patient['profile_details'] as Map)
                          : <String, dynamic>{};
                      final age = details['age']?.toString() ?? '—';
                      final village = patient['village']?.toString() ?? details['address']?.toString() ?? '—';
                      return DropdownMenuItem<String>(
                        value: name,
                        child: Text(
                          "$name – Age $age – $village",
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPatient = value;
                      });
                      if (value != null) {
                        widget.onPatientSelected(value);
                      }
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
