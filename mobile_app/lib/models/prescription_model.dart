import 'medicine_model.dart';

class PrescriptionModel {
  final String id;
  final String patientId;
  final String doctorId;
  final List<MedicineModel> medicines;
  final DateTime date;
  final String notes;

  final String? doctorName;

  PrescriptionModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.medicines,
    required this.date,
    required this.notes,
    this.doctorName,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: json['id']?.toString() ?? '',
      patientId: json['patient']?.toString() ?? '',
      doctorId: json['doctor']?.toString() ?? '',
      medicines: (json['medicines'] as List<dynamic>?)
              ?.map((m) => MedicineModel.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      date: json['issued_at'] != null ? DateTime.parse(json['issued_at']) : DateTime.now(),
      notes: json['notes'] ?? '',
      doctorName: json['doctor_name'],
    );
  }
}
