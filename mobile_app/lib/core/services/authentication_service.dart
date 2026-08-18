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

  Map<String, dynamic> _requireAuthPayload(dynamic response, String action) {
    if (response is! Map) {
      throw Exception('$action failed: unexpected server response.');
    }
    final token = response['token'];
    final user = response['user'];
    if (token is! String || token.isEmpty) {
      throw Exception('$action failed: missing token.');
    }
    if (user is! Map) {
      throw Exception('$action failed: missing user data.');
    }
    return {
      'token': token,
      'user': Map<String, dynamic>.from(user),
      ...Map<String, dynamic>.from(response),
    };
  }

  Future<void> _persistSession({
    required String token,
    required Map<String, dynamic> userData,
    String? phoneNumber,
    String? password,
    String? role,
  }) async {
    await _storageService.saveString('user_data', jsonEncode(userData));
    await _storageService.saveString('token', token);
    if (phoneNumber != null) {
      await _secureStorage.write(key: 'phone_number', value: phoneNumber);
    }
    if (password != null) {
      await _secureStorage.write(key: 'password', value: password);
    }
    if (role != null) {
      await _secureStorage.write(key: 'role', value: role);
    }
  }

  Future<Map<String, dynamic>> login(String phoneNumber, String password, String role) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    bool isOnline = connectivityResult.isNotEmpty && connectivityResult.first != ConnectivityResult.none;

    if (isOnline) {
      final response = await _apiService.post(
        ApiConstants.loginEndpoint,
        headers: {'Content-Type': 'application/json'},
        body: {
          'phone_number': phoneNumber,
          'password': password,
          'role': role,
        },
      );

      final payload = _requireAuthPayload(response, 'Login');
      await _persistSession(
        token: payload['token'] as String,
        userData: payload['user'] as Map<String, dynamic>,
        phoneNumber: phoneNumber,
        password: password,
        role: role,
      );
      return payload;
    }

    String? cachedPhone = await _secureStorage.read(key: 'phone_number');
    String? cachedPass = await _secureStorage.read(key: 'password');
    String? cachedRole = await _secureStorage.read(key: 'role');

    if (phoneNumber == cachedPhone && password == cachedPass && role == cachedRole) {
      String? cachedUserData = _storageService.getString('user_data');
      final token = _storageService.getString('token');
      if (cachedUserData != null && token != null) {
        return {
          'user': jsonDecode(cachedUserData),
          'token': token,
          'offline': true,
        };
      }
    }
    throw Exception('Invalid credentials or no offline data found for this role.');
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await _apiService.post(
      ApiConstants.registerEndpoint,
      headers: {'Content-Type': 'application/json'},
      body: data,
    );

    final payload = _requireAuthPayload(response, 'Registration');
    await _persistSession(
      token: payload['token'] as String,
      userData: payload['user'] as Map<String, dynamic>,
      phoneNumber: data['phone_number']?.toString(),
      password: data['password']?.toString(),
      role: data['role']?.toString(),
    );
    return payload;
  }

  Future<void> logout() async {
    try {
      await _apiService.post(ApiConstants.logoutEndpoint);
    } catch (_) {
      // Token may already be invalid or the device may be offline.
    }
    await _storageService.remove('user_data');
    await _storageService.remove('token');
    await _secureStorage.delete(key: 'phone_number');
    await _secureStorage.delete(key: 'password');
    await _secureStorage.delete(key: 'role');
  }

  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    final response = await _apiService.post(
      ApiConstants.sendOtpEndpoint,
      headers: {'Content-Type': 'application/json'},
      body: {'phone_number': phoneNumber},
    );
    if (response is Map<String, dynamic>) return response;
    return Map<String, dynamic>.from(response as Map);
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
    );

    final map = response is Map<String, dynamic>
        ? response
        : Map<String, dynamic>.from(response as Map);

    if (map['token'] is String && map['user'] is Map) {
      await _persistSession(
        token: map['token'] as String,
        userData: Map<String, dynamic>.from(map['user'] as Map),
        phoneNumber: phoneNumber,
        role: role,
      );
    }

    return map;
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
    );
  }

  Future<Map<String, dynamic>?> getCachedUser() async {
    String? cachedUserData = _storageService.getString('user_data');
    final token = _storageService.getString('token');
    if (cachedUserData != null && token != null && token.isNotEmpty) {
      return {
        'user': jsonDecode(cachedUserData),
        'token': token,
      };
    }
    return null;
  }
}
