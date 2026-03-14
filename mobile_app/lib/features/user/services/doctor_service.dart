import '../../../core/services/api_service.dart';

class DoctorService {
  final ApiService _apiService = ApiService();

  Future<List<Map<String, dynamic>>> getDoctors() async {
    try {
      final response = await _apiService.get('/doctors/list/');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> scheduleAppointment(int doctorId, DateTime dateTime) async {
    await _apiService.post('/consultations/', body: {
      'doctor': doctorId,
      'scheduled_at': dateTime.toIso8601String(),
    });
  }
}
