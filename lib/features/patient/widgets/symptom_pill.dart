import 'package:flutter/material.dart';

class SymptomPill extends StatelessWidget {
  final String label;

  const SymptomPill({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FF),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFF2A7DE1).withOpacity(0.1)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF2A7DE1),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
