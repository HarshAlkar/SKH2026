import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'doctor_login_screen.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/utils/helpers.dart';
import '../../../routes/app_routes.dart';

class DoctorRegisterScreen extends StatefulWidget {
  const DoctorRegisterScreen({super.key});

  @override
  State<DoctorRegisterScreen> createState() => _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends State<DoctorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailPhoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _experienceController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedSpecialization = 'General Physician';
  final List<String> _specializations = [
    'General Physician',
    'Cardiologist',
    'Dermatologist',
    'Pediatrician',
    'Orthopedic',
    'Neurologist'
  ];

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailPhoneController.dispose();
    _licenseController.dispose();
    _experienceController.dispose();
    _hospitalController.dispose();
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
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final emailOrPhone = _emailPhoneController.text.trim();
      final isEmail = emailOrPhone.contains('@');
      
      final registrationData = {
        'name': _nameController.text.trim(),
        isEmail ? 'email' : 'phone_number': emailOrPhone,
        'password': _passwordController.text,
        'role': 'doctor',
        'specialization': _selectedSpecialization,
        'license_number': _licenseController.text.trim(),
        'experience_years': int.tryParse(_experienceController.text) ?? 0,
        'hospital_name': _hospitalController.text.trim(),
      };
      
      final success = await authProvider.register(registrationData);
      
      if (success && mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.doctorDashboard);
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
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DoctorLoginScreen()),
            );
          },
        ),
        title: const Text(
          'Doctor Registration',
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
                        "Join Our Network",
                        style: TextStyle(
                          color: textDarkColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Empower rural communities with your medical expertise through VitalReach.",
                        style: TextStyle(
                          color: textSubColor,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Illustration placeholder
                      Center(
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.medical_information_outlined,
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
                  "Create Professional Profile",
                  style: TextStyle(
                    color: textDarkColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Please provide your credentials for verification.",
                  style: TextStyle(
                    color: textSubColor,
                    fontSize: 14,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // REGISTRATION FORM
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Full Name"),
                        _buildTextField(
                          controller: _nameController,
                          hintText: "Dr. Jane Smith",
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Full Name must not be empty';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        _buildLabel("Email or Phone"),
                        _buildTextField(
                          controller: _emailPhoneController,
                          hintText: "jane@hospital.com",
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email/Phone must not be empty';
                            }
                            // Basic validation
                            if (!value.contains('@') && double.tryParse(value) == null) {
                              return 'Enter a valid email or phone number';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        _buildLabel("Specialization"),
                        DropdownButtonFormField<String>(
                          value: _selectedSpecialization,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: textSubColor),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.medical_services_outlined, color: primaryColor, size: 20),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            filled: true,
                            fillColor: inputBgColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: primaryColor, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.redAccent),
                            ),
                          ),
                          items: _specializations.map((String val) {
                            return DropdownMenuItem(
                              value: val,
                              child: Text(val, style: const TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedSpecialization = val;
                            });
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        _buildLabel("License Number"),
                        _buildTextField(
                          controller: _licenseController,
                          hintText: "MC-12345678",
                          icon: Icons.badge_outlined,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'License Number must not be empty';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        _buildLabel("Years of Experience"),
                        _buildTextField(
                          controller: _experienceController,
                          hintText: "e.g. 5",
                          icon: Icons.work_outline,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Years of Experience must not be empty';
                            }
                            final exp = int.tryParse(value);
                            if (exp == null || exp < 0) {
                              return 'Must be a positive number';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        _buildLabel("Hospital / Clinic Name"),
                        _buildTextField(
                          controller: _hospitalController,
                          hintText: "City General Hospital",
                          icon: Icons.local_hospital_outlined,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Hospital/Clinic Name must not be empty';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        _buildLabel("Password"),
                        _buildTextField(
                          controller: _passwordController,
                          hintText: "Enter your password",
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          toggleObscure: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password must not be empty';
                            }
                            if (value.length < 8) {
                              return 'Minimum 8 characters';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        _buildLabel("Confirm Password"),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          hintText: "Confirm your password",
                          icon: Icons.verified_user_outlined,
                          obscureText: _obscureConfirmPassword,
                          toggleObscure: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords must match';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // TERMS & AGREEMENT
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _agreeTerms,
                        activeColor: primaryColor,
                        onChanged: (val) {
                          setState(() {
                            _agreeTerms = val ?? false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: textSubColor,
                            fontSize: 13,
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(text: "I certify that all provided medical license information is accurate and I agree to the "),
                            TextSpan(
                              text: "Terms of Service",
                              style: const TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: TapGestureRecognizer()..onTap = () {
                                // Navigate to Terms of Service
                              },
                            ),
                            const TextSpan(text: "."),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // PRIMARY BUTTON
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
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                "Register as Doctor",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // SECONDARY LINK
                Center(
                  child: InkWell(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DoctorLoginScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textDarkColor,
                          ),
                          children: [
                            TextSpan(text: "Already have an account? "),
                            TextSpan(
                              text: "Login",
                              style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // FOOTER
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.verified_outlined,
                      color: Color(0xFF4CAF50),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "SECURE VERIFICATION PROCESS",
                      style: TextStyle(
                        color: textSubColor.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    VoidCallback? toggleObscure,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    const primaryColor = Color(0xFF2A7DE1);
    const inputBgColor = Color(0xFFF5F7FA);

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: const Color(0xFF94A3B8),
                  size: 20,
                ),
                onPressed: toggleObscure,
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        filled: true,
        fillColor: inputBgColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}
