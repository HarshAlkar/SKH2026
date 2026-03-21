import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/utils/helpers.dart';
import '../../../routes/app_routes.dart';

class DoctorForgotPasswordScreen extends StatefulWidget {
  const DoctorForgotPasswordScreen({super.key});

  @override
  State<DoctorForgotPasswordScreen> createState() => _DoctorForgotPasswordScreenState();
}

class _DoctorForgotPasswordScreenState extends State<DoctorForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  final _settingsService = SettingsService();
  
  int _currentStep = 0; // 0: Phone, 1: OTP, 2: New Password
  bool _isLoading = false;
  bool _obscurePassword = true;

  final Color primaryBlue = const Color(0xFF2A7DE1);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);
  final Color lightBg = const Color(0xFFF8FAFC);

  @override
  void dispose() {
    _phoneController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length != 10) {
      Helpers.showSnackBar(context, 'Please enter a valid 10-digit phone number', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final response = await authProvider.sendOtp(phone);
    setState(() => _isLoading = false);

    if (response != null) {
      setState(() => _currentStep = 1);
      Helpers.showSnackBar(context, 'OTP sent to $phone');
    } else {
      Helpers.showSnackBar(context, authProvider.error ?? 'Failed to send OTP', isError: true);
    }
  }

  Future<void> _verifyOtp() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      Helpers.showSnackBar(context, 'Please enter a 6-digit OTP', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    // We use the resetPassword with an empty password just to verify OTP? 
    // Actually, our backend verify_otp can be used.
    // But for simplicity in this flow, I'll just move to next step and do a final reset call.
    // To be safe, let's verify OTP first.
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyOtp(phone, otp);
    setState(() => _isLoading = false);

    if (success) {
      setState(() => _currentStep = 2);
    } else {
      Helpers.showSnackBar(context, authProvider.error ?? 'Invalid OTP', isError: true);
    }
  }

  Future<void> _resetPassword() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (newPass.length < 6) {
      Helpers.showSnackBar(context, 'Password must be at least 6 characters', isError: true);
      return;
    }
    if (newPass != confirmPass) {
      Helpers.showSnackBar(context, 'Passwords do not match', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final success = await _settingsService.resetPassword(phone, otp, newPass);
    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
            content: const Text(
              'Password updated successfully! You can now login with your new password.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.roleSelection, (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Go to Login', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      }
    } else {
      Helpers.showSnackBar(context, 'Failed to update password', isError: true);
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
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Reset Password',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStepIndicator(),
            const SizedBox(height: 40),
            if (_currentStep == 0) _buildPhoneStep(),
            if (_currentStep == 1) _buildOtpStep(),
            if (_currentStep == 2) _buildNewPasswordStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepCircle(0, 'Phone'),
        _stepLine(0),
        _stepCircle(1, 'OTP'),
        _stepLine(1),
        _stepCircle(2, 'New Pass'),
      ],
    );
  }

  Widget _stepCircle(int index, String label) {
    bool isActive = _currentStep >= index;
    bool isDone = _currentStep > index;

    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isDone ? Colors.green : (isActive ? primaryBlue : Colors.grey.shade300),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone 
              ? const Icon(Icons.check, size: 18, color: Colors.white)
              : Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: isActive ? textPrimary : textSecondary)),
      ],
    );
  }

  Widget _stepLine(int index) {
    bool isActive = _currentStep > index;
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(left: 4, right: 4, bottom: 15),
      color: isActive ? Colors.green : Colors.grey.shade300,
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Enter your registered phone number to receive an OTP.', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 32),
        _buildInputField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: '10-digit number',
          icon: Icons.phone_android,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 40),
        _buildActionButton(
          text: 'Send OTP',
          onPressed: _isLoading ? null : _sendOtp,
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('We have sent a 6-digit code to ${_phoneController.text}.', style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 32),
        _buildInputField(
          controller: _otpController,
          label: 'OTP Code',
          hint: 'Enter 6-digit OTP',
          icon: Icons.lock_clock_outlined,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isLoading ? null : _sendOtp,
          child: Text('Resend OTP', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 32),
        _buildActionButton(
          text: 'Verify OTP',
          onPressed: _isLoading ? null : _verifyOtp,
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('OTP verified! Now create a strong new password.', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 32),
        _buildInputField(
          controller: _newPasswordController,
          label: 'New Password',
          hint: 'Min 6 characters',
          icon: Icons.lock_outline,
          obscure: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: textSecondary),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 20),
        _buildInputField(
          controller: _confirmPasswordController,
          label: 'Confirm New Password',
          hint: 'Re-enter new password',
          icon: Icons.lock_outline,
          obscure: _obscurePassword,
        ),
        const SizedBox(height: 40),
        _buildActionButton(
          text: 'Update Password',
          onPressed: _isLoading ? null : _resetPassword,
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: TextStyle(color: textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: primaryBlue, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: lightBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({required String text, VoidCallback? onPressed}) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
