enum UrgencyLevel { normal, moderate, urgent }
enum ConsultationType { videoCall, audioCall, chatMessage }
enum ConsultationStatus { pending, approved, adviceProvided, completed, rejected }

class ConsultationModel {
  final String id;
  final String patientName;
  final String doctorName; // Added doctorName
  final String symptoms;
  final UrgencyLevel urgency; // Changed urgencyLevel to urgency
  final ConsultationType type; // Changed consultationType to type
  final DateTime timestamp;
  final ConsultationStatus status;

  ConsultationModel({
    required this.id,
    required this.patientName,
    required this.doctorName,
    required this.symptoms,
    required this.urgency,
    required this.type,
    required this.timestamp,
    this.status = ConsultationStatus.pending,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientName': patientName,
    'doctorName': doctorName,
    'symptoms': symptoms,
    'urgency': urgency.index,
    'type': type.index,
    'timestamp': timestamp.toIso8601String(),
    'status': status.index,
  };
}
