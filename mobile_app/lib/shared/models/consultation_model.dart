enum UrgencyLevel { normal, moderate, urgent, emergency }
enum ConsultationType { videoCall, audioCall, chatMessage, physicalVisit }
enum ConsultationStatus { pending, approved, inProgress, adviceProvided, completed, cancelled, rejected }

class ConsultationModel {
  final String id;
  final String? doctorId;
  final String? doctorName;
  final String? patientId;
  final String? patientName;
  final String? symptoms;
  final UrgencyLevel urgency;
  final ConsultationType type;
  final ConsultationStatus status;
  final DateTime timestamp;
  final String? notes;
  final String? meetingLink;

  ConsultationModel({
    required this.id,
    this.doctorId,
    this.doctorName,
    this.patientId,
    this.patientName,
    this.symptoms,
    this.urgency = UrgencyLevel.normal,
    this.type = ConsultationType.videoCall,
    this.status = ConsultationStatus.pending,
    required this.timestamp,
    this.notes,
    this.meetingLink,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    return ConsultationModel(
      id: json['id']?.toString() ?? '',
      doctorId: (json['doctor_user_id'] ?? json['doctor_id'] ?? json['doctor'])?.toString(),
      doctorName: (json['doctor_full_name'] ?? json['doctor_name'] ?? json['doctor'])?.toString(),
      patientId: json['patient_id']?.toString() ?? json['patient']?.toString(),
      patientName: json['patient_name']?.toString() ?? json['patient']?.toString(),
      symptoms: json['symptoms']?.toString(),
      urgency: _parseUrgency(json['urgency'] ?? json['urgency_level']),
      type: _parseType(json['call_type'] ?? json['type']),
      status: _parseStatus(json['status']),
      timestamp: DateTime.tryParse(json['created_at'] ?? json['timestamp'] ?? '') ?? DateTime.now(),
      notes: json['notes']?.toString(),
      meetingLink: json['meeting_link']?.toString(),
    );
  }

  static UrgencyLevel _parseUrgency(dynamic val) {
    if (val is int) {
      if (val >= 0 && val < UrgencyLevel.values.length) return UrgencyLevel.values[val];
      return UrgencyLevel.normal;
    }
    final s = val?.toString().toLowerCase();
    if (s == 'moderate') return UrgencyLevel.moderate;
    if (s == 'urgent') return UrgencyLevel.urgent;
    if (s == 'emergency') return UrgencyLevel.emergency;
    return UrgencyLevel.normal;
  }

  static ConsultationType _parseType(dynamic val) {
    if (val is int) {
      if (val >= 0 && val < ConsultationType.values.length) return ConsultationType.values[val];
      return ConsultationType.videoCall;
    }
    final s = val?.toString().toLowerCase();
    if (s == 'audio_call' || s == 'audiocall' || s == 'voice') return ConsultationType.audioCall;
    if (s == 'chat' || s == 'message') return ConsultationType.chatMessage;
    if (s == 'visit') return ConsultationType.physicalVisit;
    return ConsultationType.videoCall;
  }

  static ConsultationStatus _parseStatus(dynamic val) {
    if (val is int) {
      if (val >= 0 && val < ConsultationStatus.values.length) return ConsultationStatus.values[val];
      return ConsultationStatus.pending;
    }
    final s = val?.toString().toLowerCase();
    if (s == 'approved') return ConsultationStatus.approved;
    if (s == 'in_progress' || s == 'ongoing') return ConsultationStatus.inProgress;
    if (s == 'advice_provided' || s == 'advised') return ConsultationStatus.adviceProvided;
    if (s == 'completed' || s == 'done') return ConsultationStatus.completed;
    if (s == 'cancelled') return ConsultationStatus.cancelled;
    if (s == 'rejected') return ConsultationStatus.rejected;
    return ConsultationStatus.pending;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientName': patientName,
    'doctorName': doctorName,
    'symptoms': symptoms,
    'urgency': urgency.index,
    'type': type.index,
    'timestamp': timestamp.toIso8601String(),
    'status': status.index,
    'meeting_link': meetingLink,
  };
}
