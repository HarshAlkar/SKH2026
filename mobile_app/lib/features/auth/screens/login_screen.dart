import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/helpers.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _phoneController.text,
        _passwordController.text,
        'user',
      );
      
      if (success && mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.userDashboard);
      } else if (mounted) {
        Helpers.showSnackBar(
          context,
          authProvider.error ?? 'Login failed. Please check your credentials.',
          isError: true,
        );
      }
    }
  }

  Future<void> _handleOtpLogin() async {
    if (_phoneController.text.length != 10) {
      Helpers.showSnackBar(context, 'Please enter a valid 10-digit phone number', isError: true);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final response = await authProvider.sendOtp(_phoneController.text);

    if (response != null && mounted) {
      Navigator.pushNamed(
        context, 
        AppRoutes.loginWithOtp,
        arguments: {
          'phoneNumber': _phoneController.text,
          'role': 'user',
          'isForgotPassword': false,
          'debugOtp': response['otp'],
        },
      );
    } else if (mounted) {
      Helpers.showSnackBar(
        context,
        authProvider.error ?? 'Failed to send OTP. Is your phone number registered?',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Top Section: Icon & Title
                  _buildHeader(),
                  const SizedBox(height: 40),

                  // Login Form
                  _buildLoginForm(),
                  const SizedBox(height: 16),

                  // Actions: Remember Me & Forgot Password
                  _buildMiddleActions(),
                  const SizedBox(height: 24),

                  // Primary Login Button
                  _buildLoginButton(),
                  const SizedBox(height: 24),

                  // Secondary Action: Create Account
                  _buildSecondaryActions(),
                  const SizedBox(height: 32),

                  // Info Card
                  _buildInfoCard(),
                  const SizedBox(height: 32),

                  // Bottom Section: Banner
                  _buildBottomBanner(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/images/VitalReach_logo.png',
          width: 250, // Increased to fit the text in logo
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12), // Square-ish
                color: AppColors.primary.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.health_and_safety,
                size: 50,
                color: AppColors.primary,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.number,
          validator: (value) => Validators.validatePhone(value),
          decoration: InputDecoration(
            hintText: 'Enter 10-digit mobile number',
            prefixIcon: const Icon(
              Icons.phone_outlined,
              color: AppColors.textSecondary,
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
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Password',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.forgotPassword),
              child: const Text(
                'Forgot?',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          validator: (value) => Validators.validatePassword(value),
          decoration: InputDecoration(
            hintText: 'Enter your password',
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: AppColors.textSecondary,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textSecondary,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
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

  Widget _buildMiddleActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (value) => setState(() => _rememberMe = value!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Remember me',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        GestureDetector(
          onTap: _handleOtpLogin,
          child: const Row(
            children: [
              Text(
                'Login with OTP',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.arrow_forward, size: 16, color: AppColors.secondary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: auth.isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.login_outlined),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSecondaryActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'New user? ',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.register),
          child: const Text(
            'Create Account',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Use this app to check symptoms, track medicines, and consult doctors directly from your phone. Connecting rural healthcare.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBanner() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: AssetImage('assets/images/doctor_banner.png'),
          fit: BoxFit.cover,
        ),
      ),
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.all(16),
      child: const Text(
        'Your health is our priority, \nwherever you are.',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
        ),
      ),
    );
  }
}
