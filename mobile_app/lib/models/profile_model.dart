class FamilyMemberModel {
  final int? id;
  final String name;
  final String relationship;
  final int age;
  final String phoneNumber;

  FamilyMemberModel({
    this.id,
    required this.name,
    required this.relationship,
    required this.age,
    required this.phoneNumber,
  });

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) {
    return FamilyMemberModel(
      id: json['id'],
      name: json['name'] ?? '',
      relationship: json['relationship'] ?? '',
      age: json['age'] ?? 0,
      phoneNumber: json['phone_number'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'relationship': relationship,
        'age': age,
        'phone_number': phoneNumber,
      };
}

class EmergencyInfoModel {
  final int? id;
  final String contactName;
  final String relationship;
  final String phoneNumber;
  final String alternativePhone;
  final String bloodGroup;
  final String medicalNotes;
  final String allergies;

  EmergencyInfoModel({
    this.id,
    required this.contactName,
    required this.relationship,
    required this.phoneNumber,
    this.alternativePhone = '',
    this.bloodGroup = '',
    this.medicalNotes = '',
    this.allergies = '',
  });

  factory EmergencyInfoModel.fromJson(Map<String, dynamic> json) {
    return EmergencyInfoModel(
      id: json['id'],
      contactName: json['contact_name'] ?? '',
      relationship: json['relationship'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      alternativePhone: json['alternative_phone'] ?? '',
      bloodGroup: json['blood_group'] ?? '',
      medicalNotes: json['medical_notes'] ?? '',
      allergies: json['allergies'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'contact_name': contactName,
        'relationship': relationship,
        'phone_number': phoneNumber,
        'alternative_phone': alternativePhone,
        'blood_group': bloodGroup,
        'medical_notes': medicalNotes,
        'allergies': allergies,
      };
}

class ProfileModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String phoneNumber;
  final String village;
  final String abhaId;
  final int? age;
  final String? gender;
  final String? bloodGroup;
  final List<FamilyMemberModel> familyMembers;
  final EmergencyInfoModel? emergencyInfo;

  ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phoneNumber,
    required this.village,
    required this.abhaId,
    this.age,
    this.gender,
    this.bloodGroup,
    this.familyMembers = const [],
    this.emergencyInfo,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final details = json['profile_details'] as Map<String, dynamic>?;
    return ProfileModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      phoneNumber: json['phone_number'] ?? '',
      village: json['village'] ?? '',
      abhaId: details?['abha_id'] ?? json['abha_id'] ?? '',
      age: details?['age'],
      gender: details?['gender'],
      bloodGroup: details?['blood_group'],
    );
  }
}
