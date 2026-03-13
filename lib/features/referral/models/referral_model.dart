class ReferralModel {
  final String patientName;
  final String patientId;
  final List<String> symptoms;
  final String severity;
  final DateTime timestamp;
  final String referralStatus;

  ReferralModel({
    required this.patientName,
    required this.patientId,
    required this.symptoms,
    required this.severity,
    required this.timestamp,
    required this.referralStatus,
  });
}
