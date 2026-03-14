enum SeverityLevel { low, medium, high, critical }

class NotificationModel {
  final String id;
  final String patientName;
  final String alertType;
  final String symptoms;
  final DateTime timestamp;
  final SeverityLevel severityLevel;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.patientName,
    required this.alertType,
    required this.symptoms,
    required this.timestamp,
    required this.severityLevel,
    this.isRead = false,
  });
}
