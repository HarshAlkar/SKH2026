enum AlertSeverity { urgent, moderate, normal }

class AlertModel {
  final String patientName;
  final String alertType;
  final String description;
  final String timestamp;
  final AlertSeverity severityLevel;
  final String patientPhone;

  AlertModel({
    required this.patientName,
    required this.alertType,
    required this.description,
    required this.timestamp,
    required this.severityLevel,
    this.patientPhone = "0000000000",
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    String severityStr = json['severity']?.toString().toLowerCase() ?? 'normal';
    AlertSeverity severity;
    if (severityStr == 'highrisk' || severityStr == 'urgent' || severityStr == 'high risk' || severityStr == 'severe') {
      severity = AlertSeverity.urgent;
    } else if (severityStr == 'moderate') {
      severity = AlertSeverity.moderate;
    } else {
      severity = AlertSeverity.normal;
    }

    String formattedDate = "Just now";
    if (json['created_at'] != null) {
      try {
        DateTime parsed = DateTime.parse(json['created_at']).toLocal();
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
      } catch (_) {}
    }

    return AlertModel(
      patientName: json['patient_name'] ?? 'Unknown',
      alertType: 'Health Risk',
      description: json['disease'] ?? 'No description provided.',
      timestamp: formattedDate,
      severityLevel: severity,
      patientPhone: json['patient_phone']?.toString() ?? '0000000000',
    );
  }
}
