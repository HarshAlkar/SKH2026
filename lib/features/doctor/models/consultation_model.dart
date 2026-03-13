enum ConsultationStatus { pending, adviceProvided }

enum UrgencyLevel { normal, moderate, urgent }

enum ConsultationType { video, audio, chat }

class ConsultationModel {
  final String id;
  final String doctorName;
  final String symptoms;
  final UrgencyLevel urgencyLevel;
  final ConsultationType consultationType;
  final ConsultationStatus status;
  final DateTime timestamp;
  final String? doctorAdvice;
  final String? attachedFileName;

  ConsultationModel({
    required this.id,
    required this.doctorName,
    required this.symptoms,
    required this.urgencyLevel,
    required this.consultationType,
    required this.status,
    required this.timestamp,
    this.doctorAdvice,
    this.attachedFileName,
  });

  ConsultationModel copyWith({
    String? id,
    String? doctorName,
    String? symptoms,
    UrgencyLevel? urgencyLevel,
    ConsultationType? consultationType,
    ConsultationStatus? status,
    DateTime? timestamp,
    String? doctorAdvice,
    String? attachedFileName,
  }) {
    return ConsultationModel(
      id: id ?? this.id,
      doctorName: doctorName ?? this.doctorName,
      symptoms: symptoms ?? this.symptoms,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      consultationType: consultationType ?? this.consultationType,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      doctorAdvice: doctorAdvice ?? this.doctorAdvice,
      attachedFileName: attachedFileName ?? this.attachedFileName,
    );
  }
}
