import 'package:flutter/material.dart';
import '../models/visit_model.dart';

class StatusBadge extends StatelessWidget {
  final VisitStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case VisitStatus.completed:
        color = Colors.green;
        text = "Completed";
        break;
      case VisitStatus.pending:
        color = Colors.orange;
        text = "Pending";
        break;
      case VisitStatus.missed:
        color = Colors.red;
        text = "Missed";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
