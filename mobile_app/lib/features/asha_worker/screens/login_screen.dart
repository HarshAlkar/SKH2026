import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/utils/helpers.dart';
import '../../../routes/app_routes.dart';
import '../../auth/screens/forgot_password_screen.dart';

class AshaLoginScreen extends StatefulWidget {
  const AshaLoginScreen({super.key});

  @override
  State<AshaLoginScreen> createState() => _AshaLoginScreenState();
}

class _AshaLoginScreenState extends State<AshaLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.login(
        _emailPhoneController.text,
        _passwordController.text,
        'asha_worker',
      );
      
      if (success && mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.ashaDashboard);
      } else if (mounted) {
        Helpers.showSnackBar(
          context,
          authProvider.error ?? 'Login failed. Please check your credentials.',
          isError: true,
        );
      }
    }
  }

  void _handleOtpLogin() async {
    final identifier = _emailPhoneController.text.trim();
    if (identifier.isEmpty) {
      Helpers.showSnackBar(context, 'Please enter your phone number', isError: true);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final response = await authProvider.sendOtp(identifier);

    if (response != null && mounted) {
      Navigator.pushNamed(
        context, 
        AppRoutes.loginWithOtp,
        arguments: {
          'phoneNumber': identifier,
          'role': 'asha_worker',
          'isForgotPassword': false,
          'debugOtp': response['otp'],
        },
      );
    } else if (mounted) {
      Helpers.showSnackBar(
        context,
        authProvider.error ?? 'Failed to send OTP. Is your account registered?',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF10B981); // Emerald Green for ASHA
    const accentGreen = Color(0xFF059669);
    const lightBlue = Color(0xFFECFDF5); // Light emerald background

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.roleSelection),
        ),
        title: const Text(
          'VitalReach',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {},
          ),
        ],
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // HERO IMAGE SECTION
                    Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [lightBlue, Colors.green.shade100],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -20,
                            bottom: -20,
                            child: Icon(
                              Icons.health_and_safety,
                              size: 150,
                              color: primaryColor.withOpacity(0.1),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    "Community Health Access",
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "ASHA Worker\nPortal",
                                  style: TextStyle(
                                    color: Color(0xFF1E293B),
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // DESCRIPTION TEXT
                    const Text(
                      "Manage village health data, track community visits, and assist local patients.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // LOGIN FORM
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
                            // FIELD 1
                            const Text(
                              "Worker ID or Phone Number",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailPhoneController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: "Enter your phone number",
                                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                                prefixIcon: const Icon(Icons.badge, color: primaryColor, size: 20),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
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
                                  borderSide: const BorderSide(color: primaryColor, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.redAccent),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Worker ID/Phone must not be empty';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // FIELD 2
                            const Text(
                              "Password",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: "Enter your password",
                                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                                prefixIcon: const Icon(Icons.lock_outline, color: primaryColor, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: const Color(0xFF94A3B8),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
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
                                  borderSide: const BorderSide(color: primaryColor, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.redAccent),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password must not be empty';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // HELPER LINKS
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const ForgotPasswordScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Forgot Password?",
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: _handleOtpLogin,
                                  child: const Text(
                                    "Login with OTP",
                                    style: TextStyle(
                                      color: accentGreen,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // PRIMARY BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: Consumer<AuthProvider>(
                                builder: (context, auth, _) {
                                  return ElevatedButton(
                                    onPressed: auth.isLoading ? null : _login,
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
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.login_rounded, size: 20),
                                              SizedBox(width: 8),
                                              Text(
                                                "Login as ASHA",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                  );
                                },
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // SECONDARY BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, AppRoutes.ashaRegister);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF0FDF4),
                                  foregroundColor: accentGreen,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person_add_alt_1_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      "Register as ASHA",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // SECURITY FEATURES SECTION
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "SAFE & SECURE",
                            style: TextStyle(
                              color: const Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSecurityFeature(Icons.verified_user_outlined, "Data\nPrivacy", primaryColor),
                        const SizedBox(width: 24),
                        _buildSecurityFeature(Icons.lock_outline, "Secure\nAccess", primaryColor),
                        const SizedBox(width: 24),
                        _buildSecurityFeature(Icons.support_agent_outlined, "24/7\nSupport", primaryColor),
                      ],
                    ),
                  ],
                ),
              ),
              
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityFeature(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
