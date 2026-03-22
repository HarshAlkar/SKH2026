class PatientModel {
  final String id;
  final String name;
  final int age;
  final String village;
  final String status;
  final String gender;
  final String bloodGroup;
  final String phoneNumber;
  final String address;

  PatientModel({
    required this.id,
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
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      age: int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      village: json['village'] ?? '',
      status: json['status'] ?? 'Stable',
      gender: json['gender'] ?? 'Not Set',
      bloodGroup: json['blood_group'] ?? 'Not Known',
      phoneNumber: json['phone_number'] ?? json['contact'] ?? 'N/A',
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'village': village,
      'status': status,
      'gender': gender,
      'blood_group': bloodGroup,
      'phone_number': phoneNumber,
      'address': address,
    };
  }
}
