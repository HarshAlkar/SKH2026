import 'package:flutter/material.dart';
import 'package:hs053/shared/models/alert_model.dart';

class SeverityBadge extends StatelessWidget {
  final AlertSeverity severity;

  const SeverityBadge({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (severity) {
      case AlertSeverity.urgent:
        color = const Color(0xFFE53935); // Red indicator
        text = "URGENT";
        break;
      case AlertSeverity.moderate:
        color = const Color(0xFFFFB300); // Yellow/Orange indicator
        text = "MODERATE";
        break;
      case AlertSeverity.normal:
        color = const Color(0xFF43A047); // Green indicator
        text = "NORMAL";
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
