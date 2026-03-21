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

  Future<Map<String, dynamic>?> updateDoctorProfileWithImage(Map<String, String> data, String? imagePath) async {
    try {
      final response = await _apiService.putMultipart(
        '/doctors/me/',
        fields: data,
        filePath: imagePath,
        fileField: 'profile_photo',
      );
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('Error updating doctor profile with image: $e');
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

  Future<List<Map<String, dynamic>>> getAcceptedConsultations() async {
    try {
      final response = await _apiService.get('/consultations/accepted/');
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      print('Error fetching accepted consultations: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRejectedConsultations() async {
    try {
      final response = await _apiService.get('/consultations/rejected/');
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      print('Error fetching rejected consultations: $e');
      return [];
    }
  }

  Future<bool> acceptConsultation(int id) async {
    try {
      await _apiService.post('/consultations/$id/accept_request/');
      return true;
    } catch (e) {
      print('Error accepting consultation: $e');
      return false;
    }
  }

  Future<bool> rejectConsultation(int id) async {
    try {
      await _apiService.post('/consultations/$id/reject_request/');
      return true;
    } catch (e) {
      print('Error rejecting consultation: $e');
      return false;
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

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _apiService.get('/doctors/dashboard_stats/');
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('Error fetching dashboard stats: $e');
      return {
        'pending_count': 0,
        'appointments_today': 0,
        'total_patients': 0,
        'emergency_count': 0
      };
    }
  }

  Future<List<dynamic>> getTodayAppointments() async {
    try {
      final response = await _apiService.get('/doctors/today_appointments/');
      return List<dynamic>.from(response);
    } catch (e) {
      print('Error fetching today appointments: $e');
      return [];
    }
  }
  Future<Map<String, dynamic>> getReportsStats() async {
    try {
      final response = await _apiService.get('/doctors/reports_stats/');
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('Error fetching reports stats: $e');
      return {
        'total_patients': 0,
        'patients_trend': 0,
        'critical_alerts': 0,
        'alerts_trend': 0,
        'avg_consultation_time': 0,
        'duration_trend': 0
      };
    }
  }
}
