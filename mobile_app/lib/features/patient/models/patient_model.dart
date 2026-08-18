class PatientModel {
  final String id;
  final int? userId;
  final int? patientId;
  final String name;
  final int age;
  final String village;
  final String status;

  PatientModel({
    required this.id,
    required this.name,
    required this.age,
    required this.village,
    required this.status,
    this.userId,
    this.patientId,
  });
}
