import '../core/config/app_config.dart';
import 'emergency_contact_model.dart';

class UserModel {
  final int id;
  final String name;
  final String email;
  final String role; // user, asha_worker, doctor
  final String phoneNumber;
  final String village;
  final String? photoUrl;
  final String? pendingPhotoPath;
  final Map<String, dynamic> profileDetails;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phoneNumber,
    required this.village,
    this.photoUrl,
    this.pendingPhotoPath,
    this.profileDetails = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'phone_number': phoneNumber,
        'village': village,
        'photo_url': photoUrl,
        if (pendingPhotoPath != null) 'pending_photo_path': pendingPhotoPath,
        'profile_details': profileDetails,
      };

  String? get resolvedPhotoUrl {
    final url = photoUrl?.trim() ?? '';
    if (url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '${AppConfig.origin}$url';
  }

  List<EmergencyContactModel> get emergencyContacts {
    final raw = profileDetails['emergency_contacts'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((m) => EmergencyContactModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    return [];
  }

  dynamic getDetail(String key, {dynamic fallback}) {
    final value = profileDetails[key];
    if (value == null) return fallback;
    return value;
  }

  String detail(String key, {String fallback = ''}) {
    final value = profileDetails[key];
    if (value == null) return fallback;
    return value.toString();
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    int id = 0;
    if (rawId is int) {
      id = rawId;
    } else if (rawId != null) {
      id = int.tryParse(rawId.toString()) ?? 0;
    }

    final role = json['role']?.toString() ?? 'user';
    String village = json['village']?.toString() ?? '';

    final details = json['profile_details'] is Map
        ? Map<String, dynamic>.from(json['profile_details'] as Map)
        : <String, dynamic>{};

    if (role == 'asha_worker') {
      final assigned = details['assigned_village']?.toString().trim() ?? '';
      if (assigned.isNotEmpty) village = assigned;
    }

    return UserModel(
      id: id,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: role,
      phoneNumber: json['phone_number']?.toString() ?? '',
      village: village,
      photoUrl: json['photo_url']?.toString(),
      pendingPhotoPath: json['pending_photo_path']?.toString(),
      profileDetails: details,
    );
  }
}
