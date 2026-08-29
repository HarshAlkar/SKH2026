import 'package:flutter/material.dart';
import '../../one_health/screening_disclaimer.dart';
import '../../../routes/app_routes.dart';

/// Legacy stub — kept safe for accidental navigation. Prefer SymptomCheckerScreen.
class SymptomPredictionScreen extends StatelessWidget {
  const SymptomPredictionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Screening')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.health_and_safety_outlined, size: 80, color: Colors.teal),
              const SizedBox(height: 24),
              Text(
                ScreeningDisclaimer.possibleConditionLabel('en'),
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Open the Symptom Checker for live screening.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Text(
                ScreeningDisclaimer.enHuman,
                textAlign: TextAlign.center,
                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.symptomChecker),
                child: const Text('Open Symptom Checker'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
