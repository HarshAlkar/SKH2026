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

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    SeverityLevel parseSeverity(dynamic val) {
      final s = val?.toString().toLowerCase();
      if (s == 'medium' || s == 'moderate') return SeverityLevel.medium;
      if (s == 'high' || s == 'urgent') return SeverityLevel.high;
      if (s == 'critical' || s == 'emergency') return SeverityLevel.critical;
      return SeverityLevel.low;
    }

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      patientName: json['patient_name'] ?? 'Unknown',
      alertType: json['alert_type'] ?? 'General Alert',
      symptoms: json['symptoms'] ?? json['description'] ?? json['message'] ?? '',
      timestamp: DateTime.tryParse(json['created_at'] ?? json['timestamp'] ?? '') ?? DateTime.now(),
      severityLevel: parseSeverity(json['severity'] ?? json['level']),
      isRead: json['is_read'] == true || json['is_read'] == 1,
    );
  }
}
