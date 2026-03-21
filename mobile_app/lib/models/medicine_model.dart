class MedicineModel {
  final int? id;
  final String medicineName;
  final String dosage;
  final String frequency;
  final String startDate;
  final String endDate;
  final String reminderTime;
  final String instructions;
  final bool isTaken;
  final DateTime createdAt;

  MedicineModel({
    this.id,
    required this.medicineName,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    required this.endDate,
    required this.reminderTime,
    required this.instructions,
    this.isTaken = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicine_name': medicineName,
      'dosage': dosage,
      'frequency': frequency,
      'start_date': startDate,
      'end_date': endDate,
      'reminder_time': reminderTime,
      'instructions': instructions,
      'is_taken': isTaken ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MedicineModel.fromMap(Map<String, dynamic> map) {
    return MedicineModel(
      id: map['id'],
      medicineName: map['medicine_name'] ?? map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? map['timing'] ?? '',
      startDate: map['start_date'] ?? map['duration'] ?? '',
      endDate: map['end_date'] ?? map['duration'] ?? '',
      reminderTime: map['reminder_time'] ?? '',
      instructions: map['instructions'] ?? '',
      isTaken: map['is_taken'] == 1 || map['is_taken'] == true,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicine_name': medicineName,
      'dosage': dosage,
      'frequency': frequency,
      'start_date': startDate,
      'end_date': endDate,
      'reminder_time': reminderTime,
      'instructions': instructions,
      'is_taken': isTaken,
    };
  }

  // Helper for backend mapping
  Map<String, dynamic> toBackendJson() {
    return {
      'name': medicineName,
      'dosage': dosage,
      'duration': '$startDate to $endDate', // Map dates to duration string
      'timing': frequency,
      'instructions': instructions,
    };
  }
}
