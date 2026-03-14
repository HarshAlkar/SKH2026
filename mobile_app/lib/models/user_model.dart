class UserModel {
  final int id;
  final String name;
  final String email;
  final String role; // user, asha_worker, doctor
  final String phoneNumber;
  final String village;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phoneNumber,
    required this.village,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'phone_number': phoneNumber,
    'village': village,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    role: json['role'] ?? 'user',
    phoneNumber: json['phone_number'] ?? '',
    village: json['village'] ?? '',
  );
}
