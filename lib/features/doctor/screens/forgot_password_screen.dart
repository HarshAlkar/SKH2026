import 'package:flutter/material.dart';

class DoctorForgotPasswordScreen extends StatelessWidget {
  const DoctorForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: const Center(child: Text('Forgot Password Screen')),
    );
  }
}
