import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';
import '../constants/api_constants.dart';
import 'storage_service.dart';

class AuthenticationService {
  final ApiService _apiService = ApiService();
  final _secureStorage = const FlutterSecureStorage();
  final StorageService _storageService = StorageService();

  Future<Map<String, dynamic>> login(String phoneNumber, String password, String role) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    bool isOnline = connectivityResult.isNotEmpty && connectivityResult.first != ConnectivityResult.none;

    if (isOnline) {
      try {
        final response = await _apiService.post(
          ApiConstants.loginEndpoint,
          headers: {'Content-Type': 'application/json'},
          body: {
            'phone_number': phoneNumber,
            'password': password,
            'role': role,
          },
          includeToken: false,
        );

        if (response.containsKey('two_factor_required') && response['two_factor_required'] == true) {
          return response;
        }

        // Success
        String token = response['token'];
        Map<String, dynamic> userData = response['user'];

        // Store locally for offline access
        await _storageService.saveString('user_data', jsonEncode(userData));
        await _storageService.saveString('token', token);
        
        // Securely store credentials for offline verification
        await _secureStorage.write(key: 'phone_number', value: phoneNumber);
        await _secureStorage.write(key: 'password', value: password);
        await _secureStorage.write(key: 'role', value: role);

        return response;
      } catch (e) {
        rethrow;
      }
    } else {
      // Offline Flow
      String? cachedPhone = await _secureStorage.read(key: 'phone_number');
      String? cachedPass = await _secureStorage.read(key: 'password');
      String? cachedRole = await _secureStorage.read(key: 'role');

      if (phoneNumber == cachedPhone && password == cachedPass && role == cachedRole) {
        String? cachedUserData = _storageService.getString('user_data');
        if (cachedUserData != null) {
          return {
            'user': jsonDecode(cachedUserData),
            'token': _storageService.getString('token'),
            'offline': true,
          };
        }
      }
      throw Exception('Invalid credentials or no offline data found for this role.');
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(
        ApiConstants.registerEndpoint,
        headers: {'Content-Type': 'application/json'},
        body: data,
        includeToken: false,
      );
      
      // Auto login after register
      String token = response['token'];
      Map<String, dynamic> userData = response['user'];
      await _storageService.saveString('user_data', jsonEncode(userData));
      await _storageService.saveString('token', token);
      await _secureStorage.write(key: 'phone_number', value: data['phone_number']);
      await _secureStorage.write(key: 'password', value: data['password']);

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storageService.remove('user_data');
    await _storageService.remove('token');
    await _secureStorage.delete(key: 'phone_number');
    await _secureStorage.delete(key: 'password');
  }

  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    return await _apiService.post(
      ApiConstants.sendOtpEndpoint,
      headers: {'Content-Type': 'application/json'},
      body: {'phone_number': phoneNumber},
      includeToken: false,
    );
  }

  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp, {String? role}) async {
    final response = await _apiService.post(
      ApiConstants.verifyOtpEndpoint,
      headers: {'Content-Type': 'application/json'},
      body: {
        'phone_number': phoneNumber,
        'otp': otp,
        if (role != null) 'role': role,
      },
      includeToken: false,
    );

    // If response contains token, it means it was a login verify
    if (response.containsKey('token')) {
      String token = response['token'];
      Map<String, dynamic> userData = response['user'];

      await _storageService.saveString('user_data', jsonEncode(userData));
      await _storageService.saveString('token', token);
      
      await _secureStorage.write(key: 'phone_number', value: phoneNumber);
      if (role != null) await _secureStorage.write(key: 'role', value: role);
    }

    return response;
  }

  Future<void> resetPassword(String phoneNumber, String otpCode, String newPassword) async {
    await _apiService.post(
      ApiConstants.resetPasswordEndpoint,
      headers: {'Content-Type': 'application/json'},
      body: {
        'phone_number': phoneNumber,
        'otp_code': otpCode,
        'new_password': newPassword,
      },
      includeToken: false,
    );
  }

  Future<Map<String, dynamic>?> getCachedUser() async {
    String? cachedUserData = _storageService.getString('user_data');
    if (cachedUserData != null) {
      return {
        'user': jsonDecode(cachedUserData),
        'token': _storageService.getString('token'),
      };
    }
    return null;
  }
}
