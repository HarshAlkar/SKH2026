import 'package:flutter/material.dart';

class SymptomTag extends StatelessWidget {
  final String symptom;

  const SymptomTag({super.key, required this.symptom});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD), // Light blue
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        symptom,
        style: const TextStyle(
          color: Color(0xFF1976D2),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
