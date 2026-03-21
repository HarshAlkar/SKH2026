import 'package:flutter/material.dart';
import '../../user/services/doctor_service.dart';

class EditDoctorProfileScreen extends StatefulWidget {
  final Map<String, dynamic> currentProfile;

  const EditDoctorProfileScreen({super.key, required this.currentProfile});

  @override
  State<EditDoctorProfileScreen> createState() => _EditDoctorProfileScreenState();
}

class _EditDoctorProfileScreenState extends State<EditDoctorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final DoctorService _doctorService = DoctorService();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _specializationController;
  late TextEditingController _hospitalController;
  late TextEditingController _experienceController;
  late TextEditingController _licenseController;
  late TextEditingController _qualificationController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentProfile['full_name']);
    _phoneController = TextEditingController(text: widget.currentProfile['phone_number']);
    _specializationController = TextEditingController(text: widget.currentProfile['specialization']);
    _hospitalController = TextEditingController(text: widget.currentProfile['hospital_name']);
    
    final exp = widget.currentProfile['experience_years'];
    _experienceController = TextEditingController(text: exp != null ? exp.toString() : '');
    
    _licenseController = TextEditingController(text: widget.currentProfile['license_number']);
    _qualificationController = TextEditingController(text: widget.currentProfile['qualification']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _hospitalController.dispose();
    _experienceController.dispose();
    _licenseController.dispose();
    _qualificationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; });

    final data = {
      'full_name': _nameController.text,
      'phone_number': _phoneController.text,
      'specialization': _specializationController.text,
      'hospital_name': _hospitalController.text,
      'experience_years': int.tryParse(_experienceController.text) ?? 0,
      'license_number': _licenseController.text,
      'qualification': _qualificationController.text,
    };

    final result = await _doctorService.updateDoctorProfile(data);

    setState(() { _isLoading = false; });

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.pop(context, true); // Return true to indicate success
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2A7DE1);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextFormField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _specializationController,
                      label: 'Specialization',
                      icon: Icons.local_hospital,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _qualificationController,
                      label: 'Qualification (e.g. MBBS, MD)',
                      icon: Icons.school,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _hospitalController,
                      label: 'Clinic / Hospital Name',
                      icon: Icons.business,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _experienceController,
                      label: 'Years of Experience',
                      icon: Icons.work_history,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _licenseController,
                      label: 'Medical License Number',
                      icon: Icons.badge,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _saveProfile,
                      child: const Text(
                        'Save Profile',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2A7DE1)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: validator,
      keyboardType: keyboardType,
    );
  }
}

