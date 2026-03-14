import 'package:flutter/material.dart';
import '../../../core/widgets/common_appbar.dart';
import '../../../routes/app_routes.dart';
import '../../asha_worker/widgets/asha_drawer.dart';
import '../../patient/widgets/custom_input_field.dart';

class UpdateHealthScreen extends StatefulWidget {
  const UpdateHealthScreen({super.key});

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
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call / local DB operation
      await Future.delayed(const Duration(seconds: 2));

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

        Navigator.pop(context);
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
