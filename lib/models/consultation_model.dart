class ConsultationModel {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime scheduledTime;
  final String status; // Pending, Completed, Cancelled
  final String type; // Video call, Voice call, Physical visit

  ConsultationModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.scheduledTime,
    required this.status,
    required this.type,
  });
}
