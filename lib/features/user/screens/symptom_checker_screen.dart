import 'package:flutter/material.dart';

class SymptomCheckerScreen extends StatelessWidget {
  const SymptomCheckerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check Symptoms')),
      body: const Center(child: Text('AI Symptom Input Form Here')),
    );
  }
}
