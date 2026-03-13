enum ConsultationStatus { pending, adviceProvided, completed }

enum UrgencyLevel { normal, moderate, urgent }

enum ConsultationType { videoCall, audioCall, chatMessage }

class ConsultationModel {
  final String id;
  final String doctorName;
  final String patientName;
  final String symptoms;
  final UrgencyLevel urgency;
  final ConsultationType type;
  final ConsultationStatus status;
  final DateTime timestamp;

  ConsultationModel({
    required this.id,
    required this.doctorName,
    required this.patientName,
    required this.symptoms,
    required this.urgency,
    required this.type,
    required this.status,
    required this.timestamp,
  });
}
