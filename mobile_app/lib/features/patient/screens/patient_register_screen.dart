import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/utils/helpers.dart';
import '../../../routes/app_routes.dart';

class PatientRegisterScreen extends StatefulWidget {
  const PatientRegisterScreen({super.key});

  @override
  State<PatientRegisterScreen> createState() => _PatientRegisterScreenState();
}

class _PatientRegisterScreenState extends State<PatientRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailPhoneController = TextEditingController();
  final _villageController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailPhoneController.dispose();
    _villageController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      if (!_agreeTerms) {
        Helpers.showSnackBar(
          context,
          'Please agree to the Terms of Service',
          isError: true,
        );
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        Helpers.showSnackBar(
          context,
          'Passwords do not match',
          isError: true,
        );
        return;
      }
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final registrationData = {
        'name': _nameController.text.trim(),
        'phone_number': _emailPhoneController.text.trim(),
        'password': _passwordController.text,
        'role': 'user',
        'village': _villageController.text.trim(),
      };
      
      final success = await authProvider.register(registrationData);
      
      if (success && mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.userDashboard);
      } else if (mounted) {
        Helpers.showSnackBar(
          context,
          authProvider.error ?? 'Registration failed. Please try again.',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2A7DE1);
    const lightBlue = Color(0xFFE8F1FF);
    const inputBgColor = Color(0xFFF5F7FA);
    const textDarkColor = Color(0xFF1E293B);
    const textSubColor = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () {
            Navigator.pushReplacementNamed(context, AppRoutes.userLogin);
          },
        ),
        title: const Text(
          'Patient Registration',
          style: TextStyle(
            color: textDarkColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HERO CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: lightBlue,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Join VitalReach",
                        style: TextStyle(
                          color: textDarkColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Register yourself and your family to get seamless access to healthcare.",
                        style: TextStyle(
                          color: textSubColor,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.family_restroom,
                            size: 80,
                            color: primaryColor.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // SECTION TITLE
                const Text(
                  "Create Your Profile",
                  style: TextStyle(
                    color: textDarkColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Please provide your details.",
                  style: TextStyle(
                    color: textSubColor,
                    fontSize: 14,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // REGISTRATION FORM
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PERSONAL INFO SECTION
                      _buildSectionHeader("Personal Information", Icons.person_outline, primaryColor),
                      const SizedBox(height: 16),
                      
                      _buildTextField(
                        controller: _nameController,
                        label: "Full Name",
                        hint: "Enter your full name",
                        icon: Icons.badge_outlined,
                        color: primaryColor,
                        bgColor: inputBgColor,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildTextField(
                        controller: _emailPhoneController,
                        label: "Phone Number",
                        hint: "Enter your phone number",
                        icon: Icons.phone_android_outlined,
                        color: primaryColor,
                        bgColor: inputBgColor,
                        keyboardType: TextInputType.phone,
                      ),
                      
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _villageController,
                        label: "Village / Location",
                        hint: "Enter your village name",
                        icon: Icons.home_outlined,
                        color: primaryColor,
                        bgColor: inputBgColor,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // SECURITY SECTION
                      _buildSectionHeader("Security", Icons.lock_outline, primaryColor),
                      const SizedBox(height: 16),
                      
                      // PASSWORD
                      const Text(
                        "Password",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: _buildInputDecoration("Create a password", Icons.key_outlined, primaryColor, inputBgColor).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: const Color(0xFF94A3B8),
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) => (value == null || value.length < 6) ? 'Password must be at least 6 characters' : null,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // CONFIRM PASSWORD
                      const Text(
                        "Confirm Password",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: _buildInputDecoration("Re-enter password", Icons.key_outlined, primaryColor, inputBgColor).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: const Color(0xFF94A3B8),
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                        validator: (value) => (value == null || value.isEmpty) ? 'Please confirm your password' : null,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // TERMS AND CONDITIONS
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: inputBgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _agreeTerms,
                                activeColor: primaryColor,
                                onChanged: (value) => setState(() => _agreeTerms = value ?? false),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "I verify that the information provided is accurate and I agree to the Terms of Service and Privacy Policy.",
                                style: TextStyle(
                                  color: textSubColor,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // REGISTER BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            return ElevatedButton(
                              onPressed: auth.isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: auth.isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : const Text(
                                      "Create Account",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 40),
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

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
    required Color bgColor,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: _buildInputDecoration(hint, icon, color, bgColor),
          validator: (value) => (value == null || value.trim().isEmpty) ? 'This field is required' : null,
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon, Color color, Color bgColor) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      prefixIcon: Icon(icon, color: color, size: 20),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      filled: true,
      fillColor: bgColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
