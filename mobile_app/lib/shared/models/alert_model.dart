enum AlertSeverity { urgent, moderate, normal }

class AlertModel {
  final String id;
  final String patientName;
  final String alertType;
  final String description;
  final String timestamp;
  final AlertSeverity severityLevel;
  final String patientPhone;
  final String? severity;
  final String? message;
  final String? title;

  AlertModel({
    required this.id,
    required this.patientName,
    required this.alertType,
    required this.description,
    required this.timestamp,
    required this.severityLevel,
    this.patientPhone = "0000000000",
    this.severity,
    this.message,
    this.title,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    String severityStr = (json['severity'] ?? json['severity_level'])?.toString().toLowerCase() ?? 'normal';
    AlertSeverity severity;
    if (severityStr == 'highrisk' || severityStr == 'urgent' || severityStr == 'high risk' || severityStr == 'severe' || severityStr == 'critical') {
      severity = AlertSeverity.urgent;
    } else if (severityStr == 'moderate' || severityStr == 'warning') {
      severity = AlertSeverity.moderate;
    } else {
      severity = AlertSeverity.normal;
    }

    String formattedDate = "Just now";
    if (json['created_at'] != null || json['timestamp'] != null) {
      try {
        DateTime parsed = DateTime.parse(json['created_at'] ?? json['timestamp']).toLocal();
        final now = DateTime.now();
        final diff = now.difference(parsed);
        if (diff.inMinutes < 60) {
          formattedDate = '${diff.inMinutes} mins ago';
        } else if (diff.inHours < 24) {
          formattedDate = '${diff.inHours} hours ago';
        } else if (diff.inDays == 1) {
          formattedDate = 'Yesterday';
        } else {
          formattedDate = '${diff.inDays} days ago';
        }
      } catch (_) {
        formattedDate = json['timestamp']?.toString() ?? "Just now";
      }
    }

    return AlertModel(
      id: json['id']?.toString() ?? '',
      patientName: json['patient_name'] ?? json['name'] ?? 'Unknown',
      alertType: json['alert_type'] ?? 'Health Risk',
      description: json['disease'] ?? json['message'] ?? 'No description provided.',
      timestamp: formattedDate,
      severityLevel: severity,
      patientPhone: json['patient_phone']?.toString() ?? '0000000000',
      severity: severityStr,
      message: json['message']?.toString(),
      title: json['title']?.toString() ?? 'Alert',
    );
  }
}
