import 'package:flutter/material.dart';
import 'package:hs053/shared/models/health_record_model.dart';

class RiskBadge extends StatelessWidget {
  final RiskLevel riskLevel;

  const RiskBadge({super.key, required this.riskLevel});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (riskLevel) {
      case RiskLevel.normal:
        color = Colors.green;
        text = "Normal";
        break;
      case RiskLevel.moderate:
        color = Colors.orange;
        text = "Moderate";
        break;
      case RiskLevel.highRisk:
        color = Colors.red;
        text = "High Risk";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
