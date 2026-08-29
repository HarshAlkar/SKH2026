import '../../../core/services/api_service.dart';

class DoctorService {
  final ApiService _apiService = ApiService();

  Future<List<Map<String, dynamic>>> getDoctors() async {
    try {
      final response = await _apiService.get('/doctors/');
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      print('Error fetching doctors: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> startConsultation({
    int? doctorId,
    int? patientId,
    int? ashaId,
    required String callType,
    bool isEmergency = false,
  }) async {
    final body = <String, dynamic>{
      'call_type': callType,
      if (doctorId != null) 'doctor_id': doctorId,
      if (patientId != null) 'patient_id': patientId,
      if (ashaId != null) 'asha_id': ashaId,
      if (isEmergency) 'is_emergency': true,
    };
    final response = await _apiService.post('/consultations/start/', body: body);
    return Map<String, dynamic>.from(response);
  }

  Future<void> endConsultation(String consultationId) async {
    try {
      await _apiService.post('/consultations/$consultationId/end/');
    } catch (e) {
      print('Error ending consultation: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getConsultationHistory() async {
    try {
      final response = await _apiService.get('/consultations/history/');
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      print('Error fetching history: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> bookAppointment({
    required int doctorId,
    required String date,
    required String time,
    required String type,
    String notes = '',
  }) async {
    final body = <String, dynamic>{
      'doctor_id': doctorId,
      'appointment_date': date,
      'appointment_time': time,
      'consultation_type': type.toUpperCase(),
      'notes': notes,
    };
    final response = await _apiService.post('/consultations/appointments/', body: body);
    return Map<String, dynamic>.from(response);
  }

  Future<List<Map<String, dynamic>>> getPatientAppointments() async {
    try {
      final response = await _apiService.get('/consultations/appointments/');
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      print('Error fetching patient appointments: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> smartMatch({
    required String symptoms,
    String? duration,
    String? severity,
  }) async {
    final response = await _apiService.post(
      '/consultations/appointments/smart-match/',
      body: {
        'symptoms': symptoms,
        if (duration != null && duration.isNotEmpty) 'duration': duration,
        if (severity != null && severity.isNotEmpty) 'severity': severity,
      },
    );
    if (response is Map<String, dynamic>) {
      return response;
    }
    return Map<String, dynamic>.from(response);
  }

  Future<List<String>> getDoctorSlots({
    required int doctorId,
    required String date,
  }) async {
    try {
      final response = await _apiService.get('/consultations/appointments/doctor-slots/?doctor_id=$doctorId&date=$date');
      if (response is Map && response['available_slots'] is List) {
        return List<String>.from(response['available_slots']);
      }
      return ['09:00:00', '10:30:00', '11:15:00', '12:00:00', '14:30:00', '16:00:00', '17:30:00'];
    } catch (e) {
      return ['09:00:00', '10:30:00', '11:15:00', '12:00:00', '14:30:00', '16:00:00', '17:30:00'];
    }
  }
}
