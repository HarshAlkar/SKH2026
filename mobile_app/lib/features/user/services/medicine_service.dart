import 'package:hs053/core/services/api_service.dart';

class MedicineService {
  final ApiService _apiService = ApiService();

  Future<List<Map<String, dynamic>>> getMedicines() async {
    try {
      final response = await _apiService.get('/medicines/reminders/');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getNextMedicine() async {
    try {
      final response = await _apiService.get('/medicines/reminders/next_medicine/');
      if (response is Map && response.containsKey('name')) {
        return Map<String, dynamic>.from(response);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> addMedicine(Map<String, dynamic> data) async {
    await _apiService.post('/medicines/reminders/', body: data);
  }

  Future<void> toggleMedicineStatus(int id) async {
    // Assuming backend has a toggle endpoint or we just use PATCH
    await _apiService.post('/medicines/reminders/$id/toggle/');
  }
}
