class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // villager, asha_worker, doctor
  final String phoneNumber;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'phoneNumber': phoneNumber,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    name: json['name'],
    email: json['email'],
    role: json['role'],
    phoneNumber: json['phoneNumber'],
  );
}
