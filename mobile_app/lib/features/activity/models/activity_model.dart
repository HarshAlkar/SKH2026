class ActivityModel {
  final String id;
  final String patientName;
  final String activityType;
  final String description;
  final DateTime timestamp;
  final String village;
  final String reportedBy;

  ActivityModel({
    required this.id,
    required this.patientName,
    required this.activityType,
    required this.description,
    required this.timestamp,
    required this.village,
    required this.reportedBy,
  });
}
