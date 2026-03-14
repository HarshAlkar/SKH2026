import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/common_appbar.dart';
import '../../../routes/app_routes.dart';
import '../../asha_worker/widgets/asha_drawer.dart';
import '../widgets/custom_input_field.dart';
import '../widgets/custom_dropdown_field.dart';

class RegisterPatientScreen extends StatefulWidget {
  const RegisterPatientScreen({super.key});

  @override
  State<RegisterPatientScreen> createState() => _RegisterPatientScreenState();
}

class _RegisterPatientScreenState extends State<RegisterPatientScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _villageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _diseaseController = TextEditingController();

  String? _selectedGender;
  String? _selectedBloodGroup = "Not Known";

  bool _isLoading = false;

  final Color primaryColor = const Color(0xFF2F4DB6);
  final Color lightBackground = const Color(0xFFF5F7FA);

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _villageController.dispose();
    _phoneController.dispose();
    _diseaseController.dispose();
    super.dispose();
  }

  void _handleSavePatient() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Patient registered successfully",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate back to the Dashboard/Village Patients list smoothly
        Navigator.pop(context);
      }
    }
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: const CommonAppBar(
        title: "Register New Patient",
      ),
      drawer: const AshaDrawer(currentRoute: AppRoutes.registerPatient),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // SECTION 1: BASIC DETAILS
                _buildSectionCard(
                  title: "BASIC DETAILS",
                  child: Column(
                    children: [
                      CustomInputField(
                        label: "Full Name",
                        hintText: "Enter full name",
                        prefixIcon: Icons.person,
                        controller: _nameController,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Full name cannot be empty'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: CustomInputField(
                              label: "Age",
                              hintText: "Years",
                              prefixIcon: Icons.calendar_today,
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty)
                                  return 'Required';
                                if (int.tryParse(value) == null)
                                  return 'Must be numeric';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: CustomDropdownField(
                              label: "Gender",
                              hintText: "Select",
                              items: const ["Male", "Female", "Other"],
                              value: _selectedGender,
                              onChanged: (val) =>
                                  setState(() => _selectedGender = val),
                              validator: (value) =>
                                  value == null ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // SECTION 2: LOCATION & CONTACT
                _buildSectionCard(
                  title: "LOCATION & CONTACT",
                  child: Column(
                    children: [
                      CustomInputField(
                        label: "Village",
                        hintText: "Village Name",
                        prefixIcon: Icons.location_on,
                        controller: _villageController,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      CustomInputField(
                        label: "Phone Number",
                        hintText: "10-digit mobile number",
                        prefixIcon: Icons.phone,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty)
                            return 'Required';
                          if (value.trim().length != 10)
                            return 'Must be 10 digits';
                          if (int.tryParse(value) == null)
                            return 'Must be numeric';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                // SECTION 3: MEDICAL HISTORY
                _buildSectionCard(
                  title: "MEDICAL HISTORY",
                  child: Column(
                    children: [
                      CustomDropdownField(
                        label: "Blood Group",
                        hintText: "Select blood group",
                        prefixIcon: Icons.favorite,
                        items: const [
                          "Not Known",
                          "A+",
                          "A-",
                          "B+",
                          "B-",
                          "O+",
                          "O-",
                          "AB+",
                          "AB-",
                        ],
                        value: _selectedBloodGroup,
                        onChanged: (val) =>
                            setState(() => _selectedBloodGroup = val),
                      ),
                      const SizedBox(height: 16),
                      CustomInputField(
                        label: "Existing Disease (if any)",
                        hintText: "Diabetes, Hypertension, etc.",
                        prefixIcon: Icons.info_outline,
                        controller: _diseaseController,
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // SAVE BUTTON
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleSavePatient,
                  icon: _isLoading
                      ? const SizedBox.shrink()
                      : const Icon(
                          Icons.download,
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
                          "Save Patient",
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
