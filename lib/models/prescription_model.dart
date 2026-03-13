import 'medicine_model.dart';

class PrescriptionModel {
  final String id;
  final String patientId;
  final String doctorId;
  final List<MedicineModel> medicines;
  final DateTime date;
  final String notes;

  PrescriptionModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.medicines,
    required this.date,
    required this.notes,
  });
}
