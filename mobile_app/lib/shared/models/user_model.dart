class UserModel {
  final int id;
  final String name;
  final String email;
  final String role; // user, asha_worker, doctor
  final String phoneNumber;
  final String village;
  final String? abhaId;
  final String? token;
  final Map<String, dynamic>? profileDetails;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phoneNumber,
    required this.village,
    this.abhaId,
    this.token,
    this.profileDetails,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'phone_number': phoneNumber,
    'village': village,
    'abha_id': abhaId,
    'token': token,
    'profile_details': profileDetails,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
    name: json['name'] ?? json['full_name'] ?? '',
    email: json['email'] ?? '',
    role: json['role'] ?? 'user',
    phoneNumber: json['phone_number'] ?? json['phone'] ?? '',
    village: json['village'] ?? '',
    abhaId: json['abha_id']?.toString(),
    token: json['token']?.toString() ?? json['access']?.toString() ?? json['jwt']?.toString(),
    profileDetails: json['profile_details'] is Map<String, dynamic> ? json['profile_details'] : null,
  );
}
