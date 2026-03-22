import 'dart:convert';
import 'api_service.dart';
import '../constants/api_constants.dart';

class ProfileService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      // Assuming we update the current user's patient profile
      final response = await _apiService.put('patients/me/', body: data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getFamilyMembers() async {
    try {
      final response = await _apiService.get('patients/family/');
      if (response is List) return response;
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addFamilyMember(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('patients/family/', body: data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteFamilyMember(int id) async {
    try {
      await _apiService.delete('patients/family/$id/');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchEmergencyDetails(String abhaId) async {
    try {
      final response = await _apiService.get('patients/emergency-details/?abha_id=$abhaId');
      return response;
    } catch (e) {
      rethrow;
    }
  }
  Future<Map<String, dynamic>> fetchClinicalDetails(String abhaId) async {
    try {
      final response = await _apiService.get('patients/clinical-details/?abha_id=$abhaId');
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
