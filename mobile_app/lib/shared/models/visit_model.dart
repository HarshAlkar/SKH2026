enum VisitStatus { pending, completed, missed, cancelled }

class VisitModel {
  final String id;
  final String patientName;
  final String village;
  final String visitTime;
  final DateTime visitDate;
  final VisitStatus status;
  final String notes;
  final String? patientId;

  VisitModel({
    required this.id,
    required this.patientName,
    required this.village,
    required this.visitTime,
    required this.visitDate,
    required this.status,
    this.notes = '',
    this.patientId,
  });

  VisitModel copyWith({
    String? id,
    String? patientName,
    String? village,
    String? visitTime,
    DateTime? visitDate,
    VisitStatus? status,
    String? notes,
    String? patientId,
  }) {
    return VisitModel(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      village: village ?? this.village,
      visitTime: visitTime ?? this.visitTime,
      visitDate: visitDate ?? this.visitDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      patientId: patientId ?? this.patientId,
    );
  }

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    return VisitModel(
      id: json['id']?.toString() ?? '',
      patientName: json['patient_name'] ?? 'Unknown Patient',
      village: json['village'] ?? 'Unknown Village',
      visitTime: (json['visit_time'] ?? json['time'] ?? '')?.toString() ?? '',
      visitDate: DateTime.tryParse(json['visit_date'] ?? json['date'] ?? '') ?? DateTime.now(),
      status: _parseStatus(json['status']),
      notes: json['notes'] ?? '',
      patientId: (json['patient'] ?? json['patient_id'] ?? json['patientId'])?.toString(),
    );
  }

  static VisitStatus _parseStatus(dynamic val) {
    final s = val?.toString().toUpperCase();
    switch (s) {
      case 'COMPLETED':
      case 'DONE':
        return VisitStatus.completed;
      case 'MISSED':
      case 'FAILED':
        return VisitStatus.missed;
      case 'CANCELLED':
        return VisitStatus.cancelled;
      default:
        return VisitStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status.name.toUpperCase(),
      'notes': notes,
      'visit_time': visitTime,
      'visit_date': visitDate.toIso8601String(),
    };
  }
}
