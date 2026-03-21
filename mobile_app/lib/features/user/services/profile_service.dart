import 'dart:convert';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';

class ProfileService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _apiService.get('/users/profile/me/');
      // Cache profile data as JSON for offline support
      await _storageService.saveString('cached_profile', jsonEncode(response));
      return Map<String, dynamic>.from(response);
    } catch (e) {
      // Return cached data if offline
      final cached = _storageService.getString('cached_profile');
      if (cached != null) {
        return Map<String, dynamic>.from(jsonDecode(cached));
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiService.put('/users/profile/me/', body: data);
    await _storageService.saveString('cached_profile', jsonEncode(response));
    return Map<String, dynamic>.from(response);
  }

  Future<List<Map<String, dynamic>>> getFamilyMembers() async {
    try {
      final response = await _apiService.get('/users/family-members/');
      final list = List<Map<String, dynamic>>.from(response);
      await _storageService.saveString('cached_family', jsonEncode(list));
      return list;
    } catch (e) {
      final cached = _storageService.getString('cached_family');
      if (cached != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(cached));
      }
      rethrow;
    }
  }

  Future<void> addFamilyMember(Map<String, dynamic> data) async {
    await _apiService.post('/users/family-members/', body: data);
  }

  Future<void> deleteFamilyMember(int memberId) async {
    await _apiService.delete('/users/family-members/$memberId/');
  }

  Future<Map<String, dynamic>> getEmergencyInfo() async {
    try {
      final response = await _apiService.get('/users/emergency-info/');
      await _storageService.saveString('cached_emergency', jsonEncode(response));
      return Map<String, dynamic>.from(response);
    } catch (e) {
      final cached = _storageService.getString('cached_emergency');
      if (cached != null) {
        return Map<String, dynamic>.from(jsonDecode(cached));
      }
      rethrow;
    }
  }

  Future<void> updateEmergencyInfo(Map<String, dynamic> data) async {
    await _apiService.post('/users/emergency-info/', body: data);
  }
}
