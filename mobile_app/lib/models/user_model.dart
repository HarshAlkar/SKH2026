class UserModel {
  final int id;
  final String name;
  final String email;
  final String role; // user, asha_worker, doctor
  final String phoneNumber;
  final String village;
  final bool twoFactorEnabled;
  final bool consultationRequestsEnabled;
  final String appLanguage;
  final double fontSize;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phoneNumber,
    required this.village,
    required this.twoFactorEnabled,
    required this.consultationRequestsEnabled,
    required this.appLanguage,
    required this.fontSize,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'phone_number': phoneNumber,
    'village': village,
    'two_factor_enabled': twoFactorEnabled,
    'consultation_requests_enabled': consultationRequestsEnabled,
    'app_language': appLanguage,
    'font_size': fontSize,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    role: json['role'] ?? 'user',
    phoneNumber: json['phone_number'] ?? '',
    village: json['village'] ?? '',
    twoFactorEnabled: json['two_factor_enabled'] ?? false,
    consultationRequestsEnabled: json['consultation_requests_enabled'] ?? true,
    appLanguage: json['app_language'] ?? 'English',
    fontSize: (json['font_size'] ?? 1.0).toDouble(),
  );
}
