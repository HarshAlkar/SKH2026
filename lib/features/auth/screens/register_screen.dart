import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/helpers.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _villageController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // State variables
  String? _selectedGender;
  String? _selectedBloodGroup;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _villageController.dispose();
    _conditionsController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        Helpers.showSnackBar(context, 'Passwords do not match', isError: true);
        return;
      }

      setState(() => _isLoading = true);
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        Helpers.showSnackBar(context, 'Registration Successful! Please login.');
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
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
                      _buildSectionCard(
                        title: 'Personal Details',
                        icon: Icons.person_outline,
                        children: [
                          _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            placeholder: 'Enter your full name',
                            icon: Icons.badge_outlined,
                            validator: (v) => Validators.validateRequired(v, 'Full Name'),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: _buildTextField(
                                  controller: _ageController,
                                  label: 'Age',
                                  placeholder: 'Age',
                                  icon: Icons.cake_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (v) => Validators.validateRequired(v, 'Age'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: _buildDropdownField(
                                  label: 'Gender',
                                  value: _selectedGender,
                                  items: _genders,
                                  placeholder: 'Select',
                                  icon: Icons.wc_outlined,
                                  onChanged: (v) => setState(() => _selectedGender = v),
                                  validator: (v) => Validators.validateRequired(v, 'Gender'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            placeholder: '+91 00000 00000',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (v) => Validators.validatePhone(v),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _villageController,
                            label: 'Village / Location',
                            placeholder: 'Enter your village name',
                            icon: Icons.location_on_outlined,
                            validator: (v) => Validators.validateRequired(v, 'Village/Location'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSectionCard(
                        title: 'Health Information',
                        icon: Icons.health_and_safety_outlined,
                        children: [
                          _buildDropdownField(
                            label: 'Blood Group',
                            value: _selectedBloodGroup,
                            items: _bloodGroups,
                            placeholder: 'Select Blood Group',
                            icon: Icons.bloodtype_outlined,
                            onChanged: (v) => setState(() => _selectedBloodGroup = v),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _conditionsController,
                            label: 'Existing Health Conditions',
                            placeholder: 'e.g. Diabetes, Blood Pressure, Allergies',
                            icon: Icons.medical_services_outlined,
                            maxLines: 3,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSectionCard(
                        title: 'Security',
                        icon: Icons.lock_outline,
                        children: [
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Password',
                            placeholder: 'Create password',
                            icon: Icons.vpn_key_outlined,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                            validator: (v) {
                              if (v == null || v.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password',
                            placeholder: 'Repeat password',
                            icon: Icons.shield_outlined,
                            isPassword: true,
                            obscureText: _obscureConfirmPassword,
                            onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            validator: (v) => Validators.validateRequired(v, 'Confirm Password'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      _buildCreateAccountButton(),
                      const SizedBox(height: 20),
                      _buildLoginLink(),
                      const SizedBox(height: 20),
                      const Text(
                        '© Available in 12 local languages for your convenience.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
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
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Image.asset(
              'assets/images/registration_header.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.health_and_safety, size: 80, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Start Your Health Journey',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Join thousands of villagers getting better care today.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required String placeholder,
    required IconData icon,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          icon: const Icon(Icons.expand_more, color: Colors.grey),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: placeholder,
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateAccountButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegistration,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary, // Green as per design
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          shadowColor: AppColors.secondary.withOpacity(0.4),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_outlined),
                  SizedBox(width: 8),
                  Text(
                    'Create Account',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Already have an account? ', style: TextStyle(color: AppColors.textSecondary)),
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
