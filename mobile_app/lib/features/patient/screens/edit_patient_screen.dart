import 'package:flutter/material.dart';
import '../../../core/widgets/common_appbar.dart';
import '../widgets/custom_input_field.dart';
import '../widgets/custom_dropdown_field.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../models/patient_model.dart';

class EditPatientScreen extends StatefulWidget {
  const EditPatientScreen({super.key});

  @override
  State<EditPatientScreen> createState() => _EditPatientScreenState();
}

class _EditPatientScreenState extends State<EditPatientScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _phoneController;
  late TextEditingController _historyController;
  late TextEditingController _addressController;

  String? _selectedGender;
  String? _selectedBloodGroup;
  
  PatientModel? _originalPatient;
  bool _initialized = false;
  bool _isLoading = false;

  final Color primaryColor = const Color(0xFF2F4DB6);
  final Color lightBackground = const Color(0xFFF5F7FA);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is PatientModel) {
        _originalPatient = args;
        _nameController = TextEditingController(text: args.name);
        _ageController = TextEditingController(text: args.age.toString());
        _phoneController = TextEditingController(text: args.phoneNumber);
        _historyController = TextEditingController(text: ""); // Will be fetched or passed
        _addressController = TextEditingController(text: args.address);
        _selectedGender = args.gender;
        _selectedBloodGroup = args.bloodGroup;
        _initialized = true;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _historyController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _handleUpdatePatient() async {
    if (_formKey.currentState!.validate() && _originalPatient != null) {
      setState(() => _isLoading = true);

      try {
        final payload = {
          'name': _nameController.text.trim(),
          'age': _ageController.text.trim(),
          'gender': _selectedGender,
          'phone_number': _phoneController.text.trim(),
          'blood_group': _selectedBloodGroup,
          'address': _addressController.text.trim(),
          'medical_history': _historyController.text.trim(),
        };

        // PUT request with ID
        await ApiService().put('${ApiConstants.patientsEndpoint}${_originalPatient!.id}/', body: payload);

        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Patient profile updated!"), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); // Return true to refresh
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _originalPatient == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: const CommonAppBar(title: "Edit Patient Profile"),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionCard(
                  title: "IDENTITY",
                  child: Column(
                    children: [
                      CustomInputField(
                        label: "Full Name",
                        controller: _nameController,
                        hintText: "Enter full name",
                        prefixIcon: Icons.person,
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomInputField(
                              label: "Age",
                              controller: _ageController,
                              hintText: "Years",
                              keyboardType: TextInputType.number,
                              prefixIcon: Icons.calendar_today,
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomDropdownField(
                              label: "Gender",
                              hintText: "Select",
                              value: _selectedGender,
                              items: const ["Male", "Female", "Other"],
                              onChanged: (v) => setState(() => _selectedGender = v),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                _buildSectionCard(
                  title: "CONTACT & LOCATION",
                  child: Column(
                    children: [
                      CustomInputField(
                        label: "Phone",
                        controller: _phoneController,
                        hintText: "10-digit number",
                        prefixIcon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      CustomInputField(
                        label: "Complete Address",
                        controller: _addressController,
                        hintText: "House#, Street, Area...",
                        prefixIcon: Icons.location_on,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),

                _buildSectionCard(
                  title: "MEDICAL INFO",
                  child: Column(
                    children: [
                      CustomDropdownField(
                        label: "Blood Group",
                        hintText: "Select",
                        value: _selectedBloodGroup,
                        items: const ["Not Known", "A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"],
                        onChanged: (v) => setState(() => _selectedBloodGroup = v),
                      ),
                      const SizedBox(height: 16),
                      CustomInputField(
                        label: "Medical History / Chronic Diseases",
                        controller: _historyController,
                        hintText: "N/A if none",
                        prefixIcon: Icons.history,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleUpdatePatient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 1)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
