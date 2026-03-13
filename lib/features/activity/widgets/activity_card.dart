import 'package:flutter/material.dart';
import '../models/activity_model.dart';

class ActivityCard extends StatelessWidget {
  final ActivityModel activity;
  final VoidCallback onTap;

  const ActivityCard({super.key, required this.activity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getIconColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getIcon(), color: _getIconColor(), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.patientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${activity.activityType} • ${activity.timestamp}",
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    if (activity.activityType.toLowerCase().contains('fever') ||
        activity.activityType.toLowerCase().contains('reported')) {
      return Icons.assignment_outlined;
    }
    if (activity.activityType.toLowerCase().contains('vaccination') ||
        activity.activityType.toLowerCase().contains('completed')) {
      return Icons.check_circle_outline;
    }
    return Icons.history;
  }

  Color _getIconColor() {
    if (activity.activityType.toLowerCase().contains('fever')) {
      return Colors.blue;
    }
    if (activity.activityType.toLowerCase().contains('vaccination')) {
      return Colors.green;
    }
    return Colors.orange;
  }
}
