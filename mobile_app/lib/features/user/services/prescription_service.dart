import '../../../core/services/api_service.dart';

class PrescriptionService {
  final ApiService _apiService = ApiService();

  Future<List<Map<String, dynamic>>> getPrescriptions() async {
    final response = await _apiService.get('/prescriptions/my-prescriptions/');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> getPrescriptionDetail(int id) async {
    final response = await _apiService.get('/prescriptions/$id/');
    return Map<String, dynamic>.from(response);
  }
}
