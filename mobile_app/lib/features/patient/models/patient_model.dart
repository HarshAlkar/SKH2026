class PatientModel {
  final int? id;
  final String name;
  final int age;
  final String village;
  final String status;
  final String gender;
  final String bloodGroup;
  final String phoneNumber;
  final String address;

  PatientModel({
    this.id,
    required this.name,
    required this.age,
    required this.village,
    required this.status,
    this.gender = 'Not Set',
    this.bloodGroup = 'Not Known',
    this.phoneNumber = 'N/A',
    this.address = '',
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'],
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      village: json['village'] ?? '',
      status: json['status'] ?? 'Stable',
      gender: json['gender'] ?? 'Not Set',
      bloodGroup: json['blood_group'] ?? 'Not Known',
      phoneNumber: json['phone_number'] ?? 'N/A',
      address: json['address'] ?? '',
    );
  }
}
