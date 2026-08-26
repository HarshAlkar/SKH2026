import 'package:flutter/material.dart';
import '../../patient/widgets/custom_input_field.dart';
import '../../../core/sync/offline_api.dart';
import '../widgets/asha_sidebar.dart';

class UpdateHealthScreen extends StatefulWidget {
  final int? initialPatientId;

  const UpdateHealthScreen({super.key, this.initialPatientId});

  @override
  State<UpdateHealthScreen> createState() => _UpdateHealthScreenState();
}

class _UpdateHealthScreenState extends State<UpdateHealthScreen> {
  final _formKey = GlobalKey<FormState>();

  final _tempController = TextEditingController();
  final _bpController = TextEditingController();
  final _sugarController = TextEditingController();
  final _weightController = TextEditingController();
  final _symptomsController = TextEditingController();

  bool _notifyDoctor = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _patients = [];
  int? _selectedPatientId;

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.initialPatientId;
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      final response = await OfflineApi.instance.get('/patients/');
      final rows = response is List ? response : <dynamic>[];
      final patients = <Map<String, dynamic>>[];
      for (final row in rows) {
        if (row is! Map) continue;
        final map = Map<String, dynamic>.from(row);
        final id = int.tryParse(map['id']?.toString() ?? '');
        if (id == null) continue;
        patients.add({'id': id, 'name': map['name'] ?? 'Patient $id'});
      }
      if (!mounted) return;
      setState(() {
        _patients = patients;
        _selectedPatientId ??= patients.isNotEmpty ? patients.first['id'] as int : null;
      });
    } catch (_) {}
  }

  final Color primaryColor = const Color(0xFF2F4DB6);
  final Color backgroundColor = const Color(0xFFF5F7FA);

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
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a patient first')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await OfflineApi.instance.post('/records/', body: {
        'patient_id': _selectedPatientId,
        'temperature': _tempController.text.trim(),
        'blood_pressure': _bpController.text.trim(),
        'blood_sugar': _sugarController.text.trim(),
        'weight': _weightController.text.trim(),
        'symptoms': _symptomsController.text.trim(),
        'notify_doctor': _notifyDoctor,
      });
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.synced ? Colors.green : Colors.orange,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: const AshaSidebar(),
      // APP BAR
      appBar: AppBar(
        title: const Text(
          "Update Health Data",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                  if (_patients.isNotEmpty)
                    DropdownButtonFormField<int>(
                      initialValue: _selectedPatientId,
                      items: _patients
                          .map(
                            (p) => DropdownMenuItem<int>(
                              value: p['id'] as int,
                              child: Text(p['name'].toString()),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _selectedPatientId = value),
                      decoration: const InputDecoration(labelText: 'Patient'),
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
                      "Saved on phone first, then synced to the cloud",
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
