import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../core/services/authentication_service.dart';
import '../core/services/signaling_service.dart';
import '../core/utils/network_errors.dart';

class AuthProvider extends ChangeNotifier {
  final AuthenticationService _authService = AuthenticationService();
  UserModel? _user;
  bool _isLoading = false;
  bool _isReady = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isReady => _isReady;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _loadCachedUser();
  }

  Future<void> ensureLoaded() async {
    if (_isReady) return;
    await _loadCachedUser();
  }

  Future<void> _loadCachedUser() async {
    try {
      final cachedData = await _authService.getCachedUser();
      if (cachedData != null &&
          cachedData['user'] is Map &&
          cachedData['token'] != null) {
        _user = UserModel.fromJson(
          Map<String, dynamic>.from(cachedData['user'] as Map),
        );
      }
    } catch (_) {
      _user = null;
    } finally {
      _isReady = true;
      notifyListeners();
    }
  }

  String _cleanError(Object e) => friendlyNetworkError(e);

  Future<bool> login(String phoneNumber, String password, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.login(phoneNumber, password, role);
      final userJson = response['user'];
      if (userJson is! Map) {
        throw Exception('Login succeeded but user data was missing.');
      }
      _user = UserModel.fromJson(Map<String, dynamic>.from(userJson));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _cleanError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.register(data);
      final userJson = response['user'];
      if (userJson is! Map) {
        throw Exception('Registration succeeded but user data was missing.');
      }
      _user = UserModel.fromJson(Map<String, dynamic>.from(userJson));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _cleanError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    SignalingService().disconnect();
    _user = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> sendOtp(String phoneNumber) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _authService.sendOtp(phoneNumber);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _error = _cleanError(e);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> verifyOtp(String phoneNumber, String otp, {String? role}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _authService.verifyOtp(phoneNumber, otp, role: role);
      final userJson = response['user'];
      final token = response['token'];
      if (userJson is! Map || token == null) {
        _error = 'OTP verified, but this number is not registered for login.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _user = UserModel.fromJson(Map<String, dynamic>.from(userJson));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _cleanError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String phoneNumber, String otpCode, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.resetPassword(phoneNumber, otpCode, newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _cleanError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
