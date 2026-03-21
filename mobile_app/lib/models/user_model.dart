class UserModel {
  final int id;
  final String name;
  final String? email;
  final String role; // user, asha_worker, doctor
  final String? phoneNumber;
  final String? abhaId;
  final String? village;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    this.email,
    required this.role,
    this.phoneNumber,
    this.village,
    this.abhaId,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email ?? '',
        'role': role,
        'phone_number': phoneNumber ?? '',
        'abha_id': abhaId ?? '',
        'village': village ?? '',
        'created_at': createdAt?.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // abha_id may be in profile_details for users
    final details = json['profile_details'] as Map<String, dynamic>?;
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'],
      role: json['role'] ?? 'user',
      phoneNumber: json['phone_number'],
      village: json['village'],
      abhaId: details?['abha_id'] ?? json['abha_id'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}
