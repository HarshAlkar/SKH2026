class PatientModel {
  final String id;
  final String name;
  final int age;
  final String village;
  final String phone;
  final String bloodGroup;
  final String status;
  final String createdAt;
  final String updatedAt;

  PatientModel({
    required this.id,
    required this.name,
    required this.age,
    required this.village,
    required this.phone,
    required this.bloodGroup,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      village: json['village'] as String,
      phone: json['phone'] as String,
      bloodGroup: json['bloodGroup'] as String,
      status: json['status'] as String,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'village': village,
      'phone': phone,
      'bloodGroup': bloodGroup,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
