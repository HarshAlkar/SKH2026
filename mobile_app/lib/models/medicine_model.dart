import 'package:intl/intl.dart';

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

  bool isScheduledForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final freq = frequency.trim().toLowerCase();

    // 1. One-time medicine (frequency is 'Once')
    if (freq == 'once' || freq == 'one-time' || freq == 'single') {
      return startDate == dateStr;
    }

    // 2. Daily recurring medicine
    if (freq == 'daily' || freq == 'twice daily' || freq == 'thrice daily' || freq.contains('day') || freq.isEmpty) {
      if (startDate.isNotEmpty && startDate.compareTo(dateStr) > 0) return false;
      if (endDate.isNotEmpty && endDate.compareTo(dateStr) < 0) return false;
      return true;
    }

    // 3. Weekly recurring medicine
    if (freq == 'weekly') {
      if (startDate.isNotEmpty && startDate.compareTo(dateStr) > 0) return false;
      if (endDate.isNotEmpty && endDate.compareTo(dateStr) < 0) return false;
      try {
        final parsedStart = DateFormat('yyyy-MM-dd').parse(startDate);
        return date.weekday == parsedStart.weekday;
      } catch (_) {
        return true;
      }
    }

    // Default fallback: date range based
    if (startDate.isNotEmpty && startDate.compareTo(dateStr) > 0) return false;
    if (endDate.isNotEmpty && endDate.compareTo(dateStr) < 0) return false;
    return true;
  }

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
      frequency: map['frequency'] ?? '',
      startDate: map['start_date'] ?? '',
      endDate: map['end_date'] ?? '',
      reminderTime: map['reminder_time'] ?? map['time'] ?? '',
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
}
