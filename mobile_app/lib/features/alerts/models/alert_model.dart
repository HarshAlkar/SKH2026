enum AlertSeverity { urgent, moderate, normal }

class AlertModel {
  final String patientName;
  final String alertType;
  final String description;
  final String timestamp;
  final AlertSeverity severityLevel;
  final String patientPhone;
  final String patientUserId;
  final bool isMedicineReminder;
  final String? medicineName;
  final String? reminderTime;
  final String? scheduledDate;
  final DateTime? rawDateTime;
  final int? medicineId;

  AlertModel({
    required this.patientName,
    required this.alertType,
    required this.description,
    required this.timestamp,
    required this.severityLevel,
    this.patientPhone = "0000000000",
    this.patientUserId = "",
    this.isMedicineReminder = false,
    this.medicineName,
    this.reminderTime,
    this.scheduledDate,
    this.rawDateTime,
    this.medicineId,
  });

  factory AlertModel.fromNotification(Map<String, dynamic> json) {
    final sev = (json['severity'] ?? '').toString();
    AlertSeverity level = AlertSeverity.normal;
    if (sev == 'Critical' || sev == 'High') {
      level = AlertSeverity.urgent;
    } else if (sev == 'Moderate') {
      level = AlertSeverity.moderate;
    }

    DateTime? created;
    final raw = json['created_at'];
    if (raw != null) {
      created = DateTime.tryParse(raw.toString());
    }

    final disease = json['disease']?.toString() ?? 'Alert';
    return AlertModel(
      patientName: json['patient_name']?.toString() ?? 'Unknown',
      alertType: disease,
      description:
          'Screening result: $disease (${json['severity'] ?? 'Unknown'}). Follow up with the patient if needed.',
      timestamp: relativeTime(created),
      severityLevel: level,
      patientPhone: json['patient_phone']?.toString() ?? '',
      patientUserId: json['patient_user_id']?.toString() ?? '',
      rawDateTime: created,
    );
  }

  factory AlertModel.fromMedicineReminder({
    int? medicineId,
    required String medicineName,
    required String dosage,
    required String reminderTime,
    required String scheduledDate,
    required DateTime occurrenceTime,
  }) {
    final bodyText = dosage.isNotEmpty
        ? "It's time to take $medicineName ($dosage)."
        : "It's time to take $medicineName.";

    return AlertModel(
      patientName: 'Self',
      alertType: '💊 Medicine Reminder',
      description: bodyText,
      timestamp: relativeTime(occurrenceTime),
      severityLevel: AlertSeverity.normal,
      isMedicineReminder: true,
      medicineName: medicineName,
      reminderTime: reminderTime,
      scheduledDate: scheduledDate,
      rawDateTime: occurrenceTime,
      medicineId: medicineId,
    );
  }
}

String relativeTime(DateTime? dt) {
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt.toLocal());
  if (diff.isNegative || diff.inSeconds < 45) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
  if (diff.inHours < 24) return '${diff.inHours} hours ago';
  if (diff.inDays == 1) return 'Yesterday';
  return '${diff.inDays} days ago';
}
