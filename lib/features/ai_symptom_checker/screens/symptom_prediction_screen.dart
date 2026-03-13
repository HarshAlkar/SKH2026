import 'package:flutter/material.dart';

class SymptomPredictionScreen extends StatelessWidget {
  const SymptomPredictionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Analysis')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.analytics, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text('Possible Diagnosis:', style: TextStyle(fontSize: 18)),
              const Text('Mild Seasonal Flu', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 16),
              const Text('Confidence Score: 87%', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              const Text('Please consult a doctor for official advice.', textAlign: TextAlign.center, style: TextStyle(fontStyle: FontStyle.italic)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () {}, child: const Text('Talk to Doctor')),
            ],
          ),
        ),
      ),
    );
  }
}
