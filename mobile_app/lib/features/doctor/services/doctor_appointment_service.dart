import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../screens/patient_details_screen.dart';

enum DoctorConsultationType { video, audio, offline }

class DoctorAppointment {
  final int id;
  final int patientId;
  final int? patientUserId;
  final int? doctorId;
  final String patientName;
  final String age;
  final String gender;
  final String village;
  final String phoneNumber;
  final String bloodGroup;
  final String rawDate;
  final String rawTime;
  final String formattedTime;
  final DoctorConsultationType type;
  final String status;
  final String historySummary;
  final String? lastPrescription;
  final String notes;

  DoctorAppointment({
    required this.id,
    required this.patientId,
    this.patientUserId,
    this.doctorId,
    required this.patientName,
    required this.age,
    required this.gender,
    required this.village,
    required this.phoneNumber,
    required this.bloodGroup,
    required this.rawDate,
    required this.rawTime,
    required this.formattedTime,
    required this.type,
    required this.status,
    required this.historySummary,
    this.lastPrescription,
    required this.notes,
  });

  factory DoctorAppointment.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['consultation_type'] ?? 'VIDEO').toString().toUpperCase();
    DoctorConsultationType type;
    if (typeStr == 'AUDIO') {
      type = DoctorConsultationType.audio;
    } else if (typeStr == 'OFFLINE') {
      type = DoctorConsultationType.offline;
    } else {
      type = DoctorConsultationType.video;
    }

    final rawTimeStr = json['appointment_time']?.toString() ?? '00:00:00';
    String formattedTime = rawTimeStr;
    try {
      final parts = rawTimeStr.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        final minute = parts[1].padLeft(2, '0');
        final ampm = hour >= 12 ? 'PM' : 'AM';
        hour = hour % 12;
        if (hour == 0) hour = 12;
        formattedTime = '${hour.toString().padLeft(2, '0')}:$minute $ampm';
      }
    } catch (_) {
      formattedTime = rawTimeStr;
    }

    final rawAge = json['patient_age'];
    String age = '—';
    if (rawAge != null && rawAge != 0 && rawAge.toString() != '0') {
      age = rawAge.toString();
    }

    final rawHistory = json['history_summary']?.toString().trim() ?? '';
    final historySummary = rawHistory.isNotEmpty
        ? rawHistory
        : 'No previous health history on file.';

    return DoctorAppointment(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      patientId: json['patient'] is int ? json['patient'] as int : int.tryParse(json['patient']?.toString() ?? '0') ?? 0,
      patientUserId: json['patient_user_id'] is int
          ? json['patient_user_id'] as int
          : int.tryParse(json['patient_user_id']?.toString() ?? ''),
      doctorId: json['doctor'] is int ? json['doctor'] as int : int.tryParse(json['doctor']?.toString() ?? ''),
      patientName: json['patient_name']?.toString() ?? 'Patient',
      age: age,
      gender: json['patient_gender']?.toString() ?? 'Not set',
      village: json['patient_village']?.toString() ?? '—',
      phoneNumber: json['patient_phone']?.toString() ?? '',
      bloodGroup: json['patient_blood_group']?.toString() ?? 'Not set',
      rawDate: json['appointment_date']?.toString() ?? '',
      rawTime: rawTimeStr,
      formattedTime: formattedTime,
      type: type,
      status: (json['status'] ?? 'SCHEDULED').toString(),
      historySummary: historySummary,
      lastPrescription: json['last_prescription']?.toString(),
      notes: json['notes']?.toString() ?? '',
    );
  }

  PatientData toPatientData() {
    return PatientData(
      name: patientName,
      age: age,
      gender: gender,
      village: village,
      bloodType: bloodGroup,
      phoneNumber: phoneNumber,
      chronicConditions: historySummary,
      pastSurgeries: 'Not recorded',
      allergies: 'Not recorded',
      symptoms: const [],
      aiInsights: 'Registered Patient with scheduled appointment.',
      userId: patientUserId,
      patientId: patientId,
    );
  }
}

class DoctorAppointmentService {
  final ApiService _api = ApiService();

  Future<List<DoctorAppointment>> getAppointments({String? date, String? status}) async {
    try {
      final queryParams = <String, String>{};
      if (date != null && date.isNotEmpty) {
        queryParams['date'] = date;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      String path = '/consultations/appointments/';
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
        path = '$path?$queryString';
      }

      final response = await _api.get(path);
      if (response is List) {
        return response.map((item) => DoctorAppointment.fromJson(Map<String, dynamic>.from(item as Map))).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching doctor appointments: $e');
      rethrow;
    }
  }

  Future<List<DoctorAppointment>> getTodayAppointments() async {
    return getAppointments(date: 'today');
  }

  Future<List<DoctorAppointment>> getUpcomingAppointments() async {
    return getAppointments(date: 'upcoming');
  }

  Future<bool> updateStatus(int appointmentId, String newStatus) async {
    try {
      await _api.patch(
        '/consultations/appointments/$appointmentId/',
        body: {'status': newStatus},
      );
      return true;
    } catch (e) {
      debugPrint('Error updating appointment status: $e');
      return false;
    }
  }
}
