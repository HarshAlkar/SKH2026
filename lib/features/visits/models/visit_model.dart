enum VisitStatus { pending, completed, missed }

class VisitModel {
  final String id;
  final String patientName;
  final String village;
  final String visitTime;
  final DateTime visitDate;
  final VisitStatus status;
  final String notes;

  VisitModel({
    required this.id,
    required this.patientName,
    required this.village,
    required this.visitTime,
    required this.visitDate,
    required this.status,
    this.notes = '',
  });

  VisitModel copyWith({
    String? id,
    String? patientName,
    String? village,
    String? visitTime,
    DateTime? visitDate,
    VisitStatus? status,
    String? notes,
  }) {
    return VisitModel(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      village: village ?? this.village,
      visitTime: visitTime ?? this.visitTime,
      visitDate: visitDate ?? this.visitDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
