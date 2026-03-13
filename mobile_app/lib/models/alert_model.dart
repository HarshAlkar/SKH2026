class AlertModel {
  final String id;
  final String title;
  final String message;
  final String severity; // Info, Warning, Emergency
  final DateTime timestamp;

  AlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.timestamp,
  });
}
