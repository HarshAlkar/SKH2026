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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    int id = 0;
    if (rawId is int) {
      id = rawId;
    } else if (rawId != null) {
      id = int.tryParse(rawId.toString()) ?? 0;
    }

    return UserModel(
      id: id,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      phoneNumber: json['phone_number']?.toString() ?? '',
      village: json['village']?.toString() ?? '',
    );
  }
}
