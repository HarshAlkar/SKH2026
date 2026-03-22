import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hs053/core/theme/app_colors.dart';
import 'package:hs053/core/routes/app_routes.dart';
import 'package:hs053/shared/providers/auth_provider.dart';
import 'package:hs053/core/utils/validators.dart';
import 'package:hs053/core/utils/helpers.dart';
import 'package:hs053/core/localization/app_localizations.dart';

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
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final lang = AppLocalizations.of(context);
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
          authProvider.error ?? lang?.translate('error_occurred') ?? 'Login failed. Please check your credentials.',
          isError: true,
        );
      }
    }
  }

  Future<void> _handleOtpLogin() async {
    final lang = AppLocalizations.of(context);
    if (_phoneController.text.length != 10) {
      Helpers.showSnackBar(context, lang?.translate('invalid_phone') ?? 'Please enter a valid 10-digit phone number', isError: true);
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
        },
      );
    } else if (mounted) {
      Helpers.showSnackBar(
        context,
        authProvider.error ?? lang?.translate('error_occurred') ?? 'Failed to send OTP. Is your phone number registered?',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context);
    
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
                  _buildLoginForm(lang),
                  const SizedBox(height: 16),

                  // Actions: Remember Me & Forgot Password
                  _buildMiddleActions(lang),
                  const SizedBox(height: 24),

                  // Primary Login Button
                  _buildLoginButton(lang),
                  const SizedBox(height: 24),

                  // Secondary Action: Create Account
                  _buildSecondaryActions(lang),
                  const SizedBox(height: 32),

                  // Info Card
                  _buildInfoCard(lang),
                  const SizedBox(height: 32),

                  // Bottom Section: Banner
                  _buildBottomBanner(lang),
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

  Widget _buildLoginForm(AppLocalizations? lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang?.translate('phone_number') ?? 'Phone Number',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.number,
          validator: (value) => Validators.validatePhone(value),
          decoration: InputDecoration(
            hintText: lang?.translate('phone_number') ?? 'Enter 10-digit mobile number',
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
            Text(
              lang?.translate('password') ?? 'Password',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.forgotPassword),
              child: Text(
                lang?.translate('forgot_password') ?? 'Forgot?',
                style: const TextStyle(
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
            hintText: lang?.translate('password') ?? 'Enter your password',
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

  Widget _buildMiddleActions(AppLocalizations? lang) {
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
            Text(
              lang?.translate('remember_me') ?? 'Remember me',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        GestureDetector(
          onTap: _handleOtpLogin,
          child: Row(
            children: [
              Text(
                lang?.translate('login_with_otp') ?? 'Login with OTP',
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(Icons.arrow_forward, size: 16, color: AppColors.secondary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(AppLocalizations? lang) {
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
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        lang?.translate('login') ?? 'Login',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.login_outlined),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSecondaryActions(AppLocalizations? lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${lang?.translate('new_user') ?? 'New user'}? ',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.register),
          child: Text(
            lang?.translate('create_account') ?? 'Create Account',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(AppLocalizations? lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              lang?.translate('app_info_desc') ?? 'Use this app to check symptoms, track medicines, and consult doctors directly from your phone. Connecting rural healthcare.',
              style: const TextStyle(
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

  Widget _buildBottomBanner(AppLocalizations? lang) {
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
      child: Text(
        lang?.translate('health_priority_banner') ?? 'Your health is our priority, \nwherever you are.',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
        ),
      ),
    );
  }
}
