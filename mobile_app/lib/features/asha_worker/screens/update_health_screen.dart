import 'package:flutter/material.dart';
import 'package:hs053/core/widgets/common_appbar.dart';
import 'package:hs053/core/routes/app_routes.dart';
import 'package:hs053/features/asha_worker/widgets/asha_drawer.dart';
import 'package:hs053/features/patient/widgets/custom_input_field.dart';
import 'package:hs053/core/services/api_service.dart';
import 'package:hs053/core/constants/api_constants.dart';

class UpdateHealthScreen extends StatefulWidget {
  final String? initialPatientId;

  const UpdateHealthScreen({super.key, this.initialPatientId});

  @override
  State<UpdateHealthScreen> createState() => _UpdateHealthScreenState();
}

class _UpdateHealthScreenState extends State<UpdateHealthScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final _tempController = TextEditingController();
  final _bpController = TextEditingController();
  final _sugarController = TextEditingController();
  final _weightController = TextEditingController();
  final _symptomsController = TextEditingController();

  bool _notifyDoctor = false;
  bool _isLoading = false;
  bool _isFetchingPatients = true;

  List<dynamic> _patients = [];
  String? _selectedPatientId;

  final Color primaryColor = const Color(0xFF2F4DB6);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.initialPatientId;
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    try {
      final response = await _apiService.get(ApiConstants.patientsEndpoint);
      if (mounted) {
        setState(() {
          _patients = response;
          // Verify initialPatientId actually exists in list to prevent Dropdown crash
          if (_selectedPatientId != null && !_patients.any((p) => p['id'].toString() == _selectedPatientId)) {
            _selectedPatientId = null;
          }
          _isFetchingPatients = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingPatients = false);
      }
    }
  }

  @override
  void dispose() {
    _tempController.dispose();
    _bpController.dispose();
    _sugarController.dispose();
    _weightController.dispose();
    _symptomsController.dispose();
    super.dispose();
  }

  void _handleUpdateRecord() async {
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a patient first.')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final payload = {
          'patient_id': _selectedPatientId,
          'temperature': _tempController.text.trim(),
          'blood_pressure': _bpController.text.trim(),
          'blood_sugar': _sugarController.text.trim(),
          'weight': _weightController.text.trim(),
          'symptoms': _symptomsController.text.trim(),
          'notify_doctor': _notifyDoctor,
        };

        await _apiService.post(ApiConstants.recordsEndpoint, body: payload);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Health record updated successfully",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const CommonAppBar(
        title: "Update Health Data",
      ),
      drawer: const AshaDrawer(currentRoute: AppRoutes.updateHealth),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Container(
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
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // PATIENT SELECTOR
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6.0),
                    child: Text(
                      "Select Patient",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  _isFetchingPatients 
                      ? const Center(child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator()))
                      : DropdownButtonFormField<String>(
                          value: _selectedPatientId,
                          hint: Text(
                            "Choose a patient",
                            style: TextStyle(color: Colors.grey[400], fontSize: 14),
                          ),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.person_outline, color: Colors.grey[400]),
                            filled: true,
                            fillColor: const Color(0xFFFAFAFA),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          items: _patients.map((p) {
                            return DropdownMenuItem<String>(
                              value: p['id'].toString(),
                              child: Text(p['name'] ?? 'Unknown'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedPatientId = val;
                            });
                          },
                          validator: (value) => value == null ? 'Required' : null,
                        ),
                  const SizedBox(height: 16),

                  // FIELD 1
                  CustomInputField(
                    label: "Temperature (°F)",
                    hintText: "98.6",
                    prefixIcon: Icons.thermostat_outlined,
                    controller: _tempController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (double.tryParse(value) == null) {
                          return 'Must be numeric';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // FIELD 2
                  CustomInputField(
                    label: "Blood Pressure (mmHg)",
                    hintText: "120/80",
                    prefixIcon: Icons.monitor_heart_outlined,
                    controller: _bpController,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!value.contains('/')) {
                          return 'Format should be like 120/80';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // FIELD 3
                  CustomInputField(
                    label: "Blood Sugar (mg/dL)",
                    hintText: "100",
                    prefixIcon: Icons.science_outlined,
                    controller: _sugarController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (double.tryParse(value) == null) {
                          return 'Must be numeric';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // FIELD 4
                  CustomInputField(
                    label: "Weight (kg)",
                    hintText: "65.0",
                    prefixIcon: Icons.scale_outlined,
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (double.tryParse(value) == null) {
                          return 'Must be numeric';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // FIELD 5
                  CustomInputField(
                    label: "Current Symptoms",
                    hintText: "Describe any symptoms reported by patient...",
                    prefixIcon: Icons.description_outlined,
                    controller: _symptomsController,
                    maxLines: 4,
                  ),

                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFE0E0E0)),
                  const SizedBox(height: 8),

                  // RISK ALERT TOGGLE
                  SwitchListTile(
                    title: const Text(
                      "Notify Doctor if risk detected",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "Alerts PHC physician immediately",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                    value: _notifyDoctor,
                    activeColor: primaryColor,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (bool value) {
                      setState(() {
                        _notifyDoctor = value;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // UPDATE BUTTON
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleUpdateRecord,
                    icon: _isLoading
                        ? const SizedBox.shrink()
                        : const Icon(
                            Icons.file_upload_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                    label: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Update Record",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // SYNC MESSAGE
                  Center(
                    child: Text(
                      "Data will be synced with Health Cloud",
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
