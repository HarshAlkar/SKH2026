import 'package:flutter/material.dart';
import 'package:hs053/shared/models/consultation_model.dart';
import 'package:intl/intl.dart';

class ConsultationCard extends StatelessWidget {
  final ConsultationModel consultation;

  const ConsultationCard({super.key, required this.consultation});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;

    switch (consultation.status) {
      case ConsultationStatus.pending:
        statusColor = Colors.orange;
        statusText = "Pending";
        break;
      case ConsultationStatus.approved:
        statusColor = Colors.purple;
        statusText = "Approved";
        break;
      case ConsultationStatus.inProgress:
        statusColor = Colors.blue;
        statusText = "In Progress";
        break;
      case ConsultationStatus.adviceProvided:
        statusColor = Colors.indigo;
        statusText = "Advice Provided";
        break;
      case ConsultationStatus.completed:
        statusColor = Colors.green;
        statusText = "Completed";
        break;
      case ConsultationStatus.cancelled:
        statusColor = Colors.grey;
        statusText = "Cancelled";
        break;
      case ConsultationStatus.rejected:
        statusColor = Colors.red;
        statusText = "Rejected";
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: statusColor.withOpacity(0.1),
            child: Icon(
              Icons.medical_services_outlined,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  consultation.doctorName ?? 'Doctor',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$statusText • ${_formatTimestamp(consultation.timestamp)}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return "${difference.inMinutes} mins ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} hrs ago";
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }
}
