enum NotificationStatus { read, unread }

enum NotificationSeverity { normal, critical }

class NotificationModel {
  final String id;
  final String patientName;
  final String alertType;
  final String symptoms;
  final String timestamp;
  final NotificationSeverity severityLevel;
  final NotificationStatus status;

  NotificationModel({
    required this.id,
    required this.patientName,
    required this.alertType,
    required this.symptoms,
    required this.timestamp,
    required this.severityLevel,
    this.status = NotificationStatus.unread,
  });

  NotificationModel copyWith({
    String? id,
    String? patientName,
    String? alertType,
    String? symptoms,
    String? timestamp,
    NotificationSeverity? severityLevel,
    NotificationStatus? status,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      alertType: alertType ?? this.alertType,
      symptoms: symptoms ?? this.symptoms,
      timestamp: timestamp ?? this.timestamp,
      severityLevel: severityLevel ?? this.severityLevel,
      status: status ?? this.status,
    );
  }
}
