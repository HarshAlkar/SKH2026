import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/alert_model.dart';
import 'severity_badge.dart';

class AlertCard extends StatelessWidget {
  final AlertModel alert;

  const AlertCard({super.key, required this.alert});

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.urgent:
        return const Color(0xFFE53935);
      case AlertSeverity.moderate:
        return const Color(0xFFFFB300);
      case AlertSeverity.normal:
        return const Color(0xFF43A047);
    }
  }

  Future<void> _contactPatient(BuildContext context) async {
    final phone = alert.patientPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.isEmpty || phone == '0000000000') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No phone number for ${alert.patientName}')),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not call $phone')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = _getSeverityColor(alert.severityLevel);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: severityColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SeverityBadge(severity: alert.severityLevel),
                        Text(
                          alert.timestamp,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${alert.alertType} – ${alert.patientName}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      alert.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _contactPatient(context),
                        icon: const Icon(
                          Icons.call_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Contact Patient',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F4DB6),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
