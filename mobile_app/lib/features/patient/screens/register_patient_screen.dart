import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_input_field.dart';
import '../widgets/custom_dropdown_field.dart';
import '../../../core/sync/offline_api.dart';
import '../../../providers/auth_provider.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final asha = context.read<AuthProvider>().user;
      final village = asha?.village.trim() ?? '';
      if (village.isNotEmpty) {
        _villageController.text = village;
      }
    });
  }

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

      try {
        final asha = context.read<AuthProvider>().user;
        final phone = _phoneController.text.trim();
        final village = _villageController.text.trim().isNotEmpty
            ? _villageController.text.trim()
            : (asha?.village ?? '');
        final result = await OfflineApi.instance.post('/users/register/', body: {
          'name': _nameController.text.trim(),
          'phone_number': phone,
          'username': phone,
          'password': phone.length >= 6 ? phone.substring(phone.length - 6) : '123456',
          'role': 'user',
          'village': village,
          'age': int.tryParse(_ageController.text.trim()) ?? 0,
          'gender': _selectedGender ?? 'Not Set',
          'blood_group': _selectedBloodGroup ?? '',
          'medical_history': _diseaseController.text.trim(),
        });
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: result.synced ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not register patient: $e')),
        );
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
      appBar: AppBar(
        title: const Text(
          "Register New Patient",
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
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
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
                        hintText: "Assigned village",
                        prefixIcon: Icons.location_on,
                        controller: _villageController,
                        readOnly: true,
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
