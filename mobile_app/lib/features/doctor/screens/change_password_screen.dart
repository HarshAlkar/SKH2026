import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../../../core/utils/helpers.dart';
import 'forgot_password_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _settingsService = SettingsService();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _isLoading = false;

  final Color primaryBlue = const Color(0xFF2A7DE1);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final oldPass = _oldPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (oldPass.isEmpty || newPass.isEmpty) {
      Helpers.showSnackBar(context, 'Please fill all fields', isError: true);
      return;
    }
    if (newPass.length < 6) {
      Helpers.showSnackBar(context, 'New password must be at least 6 characters', isError: true);
      return;
    }
    if (newPass != confirmPass) {
      Helpers.showSnackBar(context, 'Passwords do not match', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _settingsService.changePassword(oldPass, newPass);
      if (mounted) {
        Helpers.showSnackBar(context, response['message'] ?? 'Password changed successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to change password. check old password.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          'Security',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Change Password',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Your new password must be different from previously used passwords.',
              style: TextStyle(fontSize: 14, color: textSecondary),
            ),
            const SizedBox(height: 32),
            
            // Old Password
            _buildPasswordField(
              controller: _oldPasswordController,
              label: 'Old Password',
              hint: 'Enter current password',
              obscure: _obscureOld,
              toggleObscure: () => setState(() => _obscureOld = !_obscureOld),
            ),
            
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DoctorForgotPasswordScreen()),
                  );
                },
                child: Text('Forgot Password?', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // New Password
            _buildPasswordField(
              controller: _newPasswordController,
              label: 'New Password',
              hint: 'Min 6 characters',
              obscure: _obscureNew,
              toggleObscure: () => setState(() => _obscureNew = !_obscureNew),
            ),
            
            const SizedBox(height: 20),
            
            // Confirm Password
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: 'Confirm New Password',
              hint: 'Re-enter new password',
              obscure: _obscureNew,
              toggleObscure: () => setState(() => _obscureNew = !_obscureNew),
            ),
            
            const SizedBox(height: 48),
            
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Update Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback toggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(Icons.lock_outline, color: primaryBlue, size: 20),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: textSecondary),
              onPressed: toggleObscure,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}
