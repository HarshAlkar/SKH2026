import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/helpers.dart';
import '../../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Shared Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _villageController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Doctor Specific
  final _specializationController = TextEditingController();
  final _expController = TextEditingController();
  final _hospitalController = TextEditingController();

  // ASHA Specific
  final _phcController = TextEditingController();

  // State variables
  String _selectedRole = 'user';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final Map<String, String> _roles = {
    'user': 'Patient',
    'doctor': 'Doctor',
    'asha_worker': 'ASHA Worker',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _villageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _specializationController.dispose();
    _expController.dispose();
    _hospitalController.dispose();
    _phcController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        Helpers.showSnackBar(context, 'Passwords do not match', isError: true);
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final Map<String, dynamic> regData = {
        'name': _nameController.text,
        'phone_number': _phoneController.text,
        'village': _villageController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'role': _selectedRole,
      };

      if (_selectedRole == 'doctor') {
        regData['specialization'] = _specializationController.text;
        regData['experience_years'] = int.tryParse(_expController.text) ?? 0;
        regData['hospital_name'] = _hospitalController.text;
      } else if (_selectedRole == 'asha_worker') {
        regData['assigned_village'] = _villageController.text;
        regData['phc_center'] = _phcController.text;
      }

      final success = await authProvider.register(regData);

      if (success && mounted) {
        Helpers.showSnackBar(context, 'Registration Successful!');
        // Navigate to dashboard
        switch (_selectedRole) {
          case 'doctor':
            Navigator.pushReplacementNamed(context, AppRoutes.doctorDashboard);
            break;
          case 'asha_worker':
            Navigator.pushReplacementNamed(context, AppRoutes.ashaDashboard);
            break;
          default:
            Navigator.pushReplacementNamed(context, AppRoutes.userDashboard);
        }
      } else if (mounted) {
        Helpers.showSnackBar(context, authProvider.error ?? 'Registration failed', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Gramin Health Connect',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Role Selection
                      _buildRoleSelector(),
                      const SizedBox(height: 20),

                      _buildSectionCard(
                        title: 'Account Information',
                        icon: Icons.person_outline,
                        children: [
                          _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            placeholder: 'Enter your full name',
                            icon: Icons.badge_outlined,
                            validator: (v) =>
                                Validators.validateRequired(v, 'Full Name'),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            placeholder: '10-digit mobile number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (v) => Validators.validatePhone(v),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            placeholder: 'Email address',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => Validators.validateEmail(v),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _villageController,
                            label: 'Village / City',
                            placeholder: 'Enter village name',
                            icon: Icons.location_on_outlined,
                            validator: (v) => Validators.validateRequired(v, 'Village'),
                          ),
                        ],
                      ),
                      
                      if (_selectedRole == 'doctor') ...[
                        const SizedBox(height: 20),
                        _buildSectionCard(
                          title: 'Professional Details',
                          icon: Icons.medical_services_outlined,
                          children: [
                            _buildTextField(
                              controller: _specializationController,
                              label: 'Specialization',
                              placeholder: 'e.g. Cardiologist',
                              icon: Icons.star_outline,
                              validator: (v) => Validators.validateRequired(v, 'Specialization'),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _expController,
                              label: 'Experience (Years)',
                              placeholder: 'Number of years',
                              icon: Icons.timer_outlined,
                              keyboardType: TextInputType.number,
                              validator: (v) => Validators.validateRequired(v, 'Experience'),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _hospitalController,
                              label: 'Hospital Name',
                              placeholder: 'Current hospital',
                              icon: Icons.local_hospital_outlined,
                              validator: (v) => Validators.validateRequired(v, 'Hospital'),
                            ),
                          ],
                        ),
                      ],

                      if (_selectedRole == 'asha_worker') ...[
                        const SizedBox(height: 20),
                        _buildSectionCard(
                          title: 'Work Information',
                          icon: Icons.work_outline,
                          children: [
                            _buildTextField(
                              controller: _phcController,
                              label: 'PHC Center',
                              placeholder: 'Assigned PHC center',
                              icon: Icons.center_focus_weak,
                              validator: (v) => Validators.validateRequired(v, 'PHC Center'),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 20),
                      _buildSectionCard(
                        title: 'Security',
                        icon: Icons.lock_outline,
                        children: [
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Password',
                            placeholder: 'Min 6 characters',
                            icon: Icons.vpn_key_outlined,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            onToggleVisibility: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            validator: (v) => Validators.validatePassword(v),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password',
                            placeholder: 'Repeat password',
                            icon: Icons.shield_outlined,
                            isPassword: true,
                            obscureText: _obscureConfirmPassword,
                            onToggleVisibility: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                            validator: (v) {
                              if (v != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return Validators.validateRequired(
                                v,
                                'Confirm Password',
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      _buildCreateAccountButton(authProvider.isLoading),
                      const SizedBox(height: 20),
                      _buildLoginLink(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: _roles.entries.map((entry) {
          bool isSelected = _selectedRole == entry.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedRole = entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1FF),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Image.asset(
              'assets/images/registration_header.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.health_and_safety,
                size: 60,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Create Your Account',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: placeholder,
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateAccountButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleRegistration,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Register Now',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
          child: const Text(
            'Login',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
