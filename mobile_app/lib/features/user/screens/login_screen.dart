import 'package:flutter/material.dart';
import '../../auth/screens/login_screen.dart';

class UserLoginScreen extends StatelessWidget {
  const UserLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We reuse the central login screen but could pass role-specific info if needed
    return const LoginScreen();
  }
}
