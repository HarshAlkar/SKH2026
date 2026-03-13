import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    if (status.toLowerCase().contains('stable')) {
      backgroundColor = const Color(0xFFE8F5E9); // Light green
      textColor = const Color(0xFF388E3C); // Green
    } else if (status.toLowerCase().contains('due')) {
      backgroundColor = const Color(0xFFFFF8E1); // Light yellow
      textColor = const Color(0xFFF57F17); // Yellow/Orange
    } else {
      backgroundColor = Colors.grey.shade200;
      textColor = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
