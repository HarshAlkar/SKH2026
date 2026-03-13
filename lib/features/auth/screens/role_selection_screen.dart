import 'package:flutter/material.dart';
import '../../../widgets/custom_button.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Who are you?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            CustomButton(text: 'I am a Villager', onPressed: () {}),
            const SizedBox(height: 16),
            CustomButton(text: 'I am an ASHA Worker', onPressed: () {}, color: Colors.blue),
            const SizedBox(height: 16),
            CustomButton(text: 'I am a Doctor', onPressed: () {}, color: Colors.orange),
          ],
        ),
      ),
    );
  }
}
