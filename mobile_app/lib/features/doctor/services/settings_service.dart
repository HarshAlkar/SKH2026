import '../../../core/services/api_service.dart';

class SettingsService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>?> getSettings() async {
    try {
      final response = await _apiService.get('/users/settings/');
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('Error fetching settings: $e');
      return null;
    }
  }

  Future<bool> updateSettings(Map<String, dynamic> settings) async {
    try {
      await _apiService.patch('/users/settings/', body: settings);
      return true;
    } catch (e) {
      print('Error updating settings: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword) async {
    try {
      final response = await _apiService.post(
        '/users/change-password/',
        body: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );
      return Map<String, dynamic>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> resetPassword(String phoneNumber, String otpCode, String newPassword) async {
    try {
      await _apiService.post(
        '/users/reset-password/',
        body: {
          'phone_number': phoneNumber,
          'otp_code': otpCode,
          'new_password': newPassword,
        },
      );
      return true;
    } catch (e) {
      print('Error resetting password: $e');
      return false;
    }
  }
}
