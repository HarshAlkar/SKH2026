import 'package:flutter/material.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_input_field.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to Gramin Health', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            const CustomInputField(label: 'Email / Phone'),
            const SizedBox(height: 16),
            const CustomInputField(label: 'Password', isPassword: true),
            const SizedBox(height: 24),
            CustomButton(text: 'Login', onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
