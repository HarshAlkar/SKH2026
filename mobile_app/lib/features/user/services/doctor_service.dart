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

  Future<Map<String, dynamic>?> getDoctorProfile() async {
    try {
      final response = await _apiService.get('/doctors/me/');
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('Error fetching doctor profile: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateDoctorProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('/doctors/me/', body: data);
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('Error updating doctor profile: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> startConsultation({int? doctorId, int? patientId, String callType = 'VIDEO'}) async {
    final Map<String, dynamic> body = {
      'call_type': callType,
    };
    if (doctorId != null) body['doctor_id'] = doctorId;
    if (patientId != null) body['patient_id'] = patientId;

    try {
      final response = await _apiService.post('/consultations/start/', body: body);
      return Map<String, dynamic>.from(response);
    } catch (e) {
      rethrow;
    }
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

  Future<List<Map<String, dynamic>>> getPendingConsultations() async {
    try {
      final response = await _apiService.get('/consultations/pending/');
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      print('Error fetching pending consultations: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createPrescription(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/prescriptions/', body: data);
      return Map<String, dynamic>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPatients() async {
    try {
      final response = await _apiService.get('/patients/');
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      print('Error fetching patients: $e');
      return [];
    }
  }
  Future<List<Map<String, dynamic>>> getPrescriptions() async {
    try {
      final response = await _apiService.get('/prescriptions/');
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      print('Error fetching prescriptions: $e');
      return [];
    }
  }
}
