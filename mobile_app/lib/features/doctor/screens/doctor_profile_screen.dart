import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../user/services/doctor_service.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final Color primaryBlue = const Color(0xFF2A7DE1);
  final Color lightBg = const Color(0xFFF3F4F6);
  final Color cardBg = const Color(0xFFFFFFFF);
  final Color accentGreen = const Color(0xFF22C55E);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);

  final DoctorService _doctorService = DoctorService();
  bool _isLoading = true;
  bool _isEditing = false;
  Map<String, dynamic>? _doctorProfile;
  File? _newProfileImage;

  late TextEditingController _nameController;
  late TextEditingController _specializationController;
  late TextEditingController _hospitalController;
  late TextEditingController _experienceController;
  late TextEditingController _licenseController;
  late TextEditingController _qualificationController;
  late TextEditingController _consultationModeController;
  late TextEditingController _clinicLocationController;
  late TextEditingController _workingHoursController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _fetchProfile();
  }

  void _initControllers() {
    _nameController = TextEditingController();
    _specializationController = TextEditingController();
    _hospitalController = TextEditingController();
    _experienceController = TextEditingController();
    _licenseController = TextEditingController();
    _qualificationController = TextEditingController();
    _consultationModeController = TextEditingController();
    _clinicLocationController = TextEditingController();
    _workingHoursController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
  }

  void _populateControllers(Map<String, dynamic> data) {
    _nameController.text = data['full_name'] ?? '';
    _specializationController.text = data['specialization'] ?? '';
    _hospitalController.text = data['hospital_name'] ?? '';
    _experienceController.text = data['experience_years']?.toString() ?? '';
    _licenseController.text = data['license_number'] ?? '';
    _qualificationController.text = data['qualification'] ?? '';
    _consultationModeController.text = data['consultation_mode'] ?? '';
    _clinicLocationController.text = data['clinic_location'] ?? '';
    _workingHoursController.text = data['working_hours'] ?? '';
    _phoneController.text = data['phone_number'] ?? '';
    _emailController.text = data['email'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specializationController.dispose();
    _hospitalController.dispose();
    _experienceController.dispose();
    _licenseController.dispose();
    _qualificationController.dispose();
    _consultationModeController.dispose();
    _clinicLocationController.dispose();
    _workingHoursController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    final profile = await _doctorService.getDoctorProfile();
    if (mounted) {
      setState(() {
        _doctorProfile = profile;
        if (profile != null) _populateControllers(profile);
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      
      if (pickedFile != null) {
        setState(() {
          _newProfileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    setState(() { _isLoading = true; });

    final data = {
      'full_name': _nameController.text,
      'phone_number': _phoneController.text,
      'email': _emailController.text,
      'specialization': _specializationController.text,
      'hospital_name': _hospitalController.text,
      'experience_years': int.tryParse(_experienceController.text)?.toString() ?? '0',
      'license_number': _licenseController.text,
      'qualification': _qualificationController.text,
      'consultation_mode': _consultationModeController.text,
      'clinic_location': _clinicLocationController.text,
      'working_hours': _workingHoursController.text,
    };

    final result = _newProfileImage != null 
        ? await _doctorService.updateDoctorProfileWithImage(data, _newProfileImage!.path)
        : await _doctorService.updateDoctorProfile(data);

    if (mounted) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        setState(() {
          _isEditing = false;
          _doctorProfile = result;
          _populateControllers(result);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Profile' : 'Doctor Profile',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_doctorProfile != null)
            IconButton(
              icon: Icon(
                _isEditing ? Icons.check : Icons.edit,
                color: _isEditing ? accentGreen : primaryBlue,
              ),
              onPressed: () async {
                if (_isEditing) {
                  await _saveProfile();
                } else {
                  setState(() => _isEditing = true);
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _doctorProfile == null
              ? const Center(child: Text("Could not load profile"))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildProfileHeader(),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildProfessionalInfo(),
                            const SizedBox(height: 16),
                            _buildClinicInfo(),
                            const SizedBox(height: 16),
                            _buildContactInfo(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    final nameStr = _doctorProfile?['full_name'] ?? 'Doctor Name';
    final name = nameStr.toString().startsWith('Dr.') ? nameStr : 'Dr. $nameStr';
    final specialization = _doctorProfile?['specialization'] ?? 'General Physician';
    final hospital = _doctorProfile?['hospital_name'] ?? 'Not Set';
    final profilePhotoUrl = _doctorProfile?['profile_photo'] as String?;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: _isEditing ? _pickImage : null,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryBlue.withOpacity(0.1), width: 4),
                    color: primaryBlue.withOpacity(0.05),
                    image: _newProfileImage != null
                        ? DecorationImage(
                            image: FileImage(_newProfileImage!),
                            fit: BoxFit.cover,
                          )
                        : (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty)
                            ? DecorationImage(
                                image: NetworkImage(profilePhotoUrl.startsWith('http') 
                                      ? profilePhotoUrl 
                                      : 'http://127.0.0.1:8000$profilePhotoUrl'),
                                fit: BoxFit.cover,
                              )
                            : null,
                  ),
                  child: (_newProfileImage == null && (profilePhotoUrl == null || profilePhotoUrl.isEmpty))
                      ? Center(
                          child: Icon(Icons.person, size: 60, color: primaryBlue.withOpacity(0.5)),
                        )
                      : null,
                ),
              ),
              if (_isEditing)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                    ),
                  ),
                )
              else
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: accentGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isEditing) ...[
            TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Full Name',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _specializationController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Specialization',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              style: TextStyle(color: primaryBlue, fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _hospitalController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Hospital Name',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
              ),
              style: TextStyle(color: textSecondary, fontSize: 14),
            ),
          ] else ...[
            Text(
              name,
              style: TextStyle(
                color: textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              specialization,
              style: TextStyle(
                color: primaryBlue,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: textSecondary),
                const SizedBox(width: 4),
                Text(
                  hospital,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfessionalInfo() {
    final license = _doctorProfile?['license_number'] ?? 'Not Set';
    final exp = _doctorProfile?['experience_years']?.toString() ?? '0';
    final edu = _doctorProfile?['qualification'] ?? 'Not Set';
    final mode = _doctorProfile?['consultation_mode'] ?? 'Not Set';

    return _buildSectionCard(
      title: 'Professional Information',
      children: [
        _buildInfoRow(Icons.badge_outlined, 'Medical License', license, _licenseController),
        _buildInfoRow(Icons.work_outline, 'Experience (Years)', exp, _experienceController, TextInputType.number),
        _buildInfoRow(Icons.school_outlined, 'Education', edu, _qualificationController),
        _buildInfoRow(Icons.videocam_outlined, 'Consultation Mode', mode, _consultationModeController),
      ],
    );
  }

  Widget _buildClinicInfo() {
    final hospital = _doctorProfile?['hospital_name'] ?? 'Not Set';
    final loc = _doctorProfile?['clinic_location'] ?? 'Not Set';
    final hours = _doctorProfile?['working_hours'] ?? 'Not Set';
    
    return _buildSectionCard(
      title: 'Clinic Information',
      children: [
        if (!_isEditing) 
           _buildInfoRow(Icons.local_hospital_outlined, 'Clinic Name', hospital, null), // Only show hospital in static view, edited in header
        _buildInfoRow(Icons.map_outlined, 'Location', loc, _clinicLocationController),
        _buildInfoRow(Icons.access_time, 'Working Hours', hours, _workingHoursController),
      ],
    );
  }

  Widget _buildContactInfo() {
    final phone = _doctorProfile?['phone_number'] ?? 'Not Set';
    final email = _doctorProfile?['email'] ?? 'Not Set';
    
    return _buildSectionCard(
      title: 'Contact Information',
      children: [
        _buildInfoRow(Icons.phone_outlined, 'Phone Number', phone, _phoneController, TextInputType.phone),
        _buildInfoRow(Icons.email_outlined, 'Email', email, _emailController, TextInputType.emailAddress),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, TextEditingController? controller, [TextInputType? keyboardType]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: _isEditing && controller != null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: primaryBlue.withOpacity(0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: _isEditing && controller != null
              ? TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    labelText: label,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 14,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }
}
