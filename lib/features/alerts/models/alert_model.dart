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
}
