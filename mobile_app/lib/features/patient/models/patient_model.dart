class PatientModel {
  final String id;
  final int? userId;
  final int? patientId;
  final String name;
  final int age;
  final String village;
  final String status;
  final String gender;
  final String bloodGroup;
  final String address;
  final String phoneNumber;
  final String medicalHistory;

  PatientModel({
    required this.id,
    required this.name,
    required this.age,
    required this.village,
    required this.status,
    this.userId,
    this.patientId,
    this.gender = '',
    this.bloodGroup = '',
    this.address = '',
    this.phoneNumber = '',
    this.medicalHistory = '',
  });
}
