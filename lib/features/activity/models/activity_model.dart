class ActivityModel {
  final String patientName;
  final String activityType;
  final String description;
  final String timestamp;
  final String village;
  final String reportedBy;

  ActivityModel({
    required this.patientName,
    required this.activityType,
    required this.description,
    required this.timestamp,
    required this.village,
    required this.reportedBy,
  });
}
