import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../core/services/authentication_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthenticationService _authService = AuthenticationService();
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _twoFactorRequired = false;
  String? _tempPhoneNumber;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get twoFactorRequired => _twoFactorRequired;
  String? get tempPhoneNumber => _tempPhoneNumber;

  AuthProvider() {
    _loadCachedUser();
  }

  Future<void> _loadCachedUser() async {
    final cachedData = await _authService.getCachedUser();
    if (cachedData != null) {
      _user = UserModel.fromJson(cachedData['user']);
      notifyListeners();
    }
  }

  Future<bool> login(String phoneNumber, String password, String role) async {
    _isLoading = true;
    _error = null;
    _twoFactorRequired = false;
    _tempPhoneNumber = null;
    notifyListeners();

    try {
      final response = await _authService.login(phoneNumber, password, role);
      
      if (response.containsKey('two_factor_required') && response['two_factor_required'] == true) {
        _twoFactorRequired = true;
        _tempPhoneNumber = response['phone_number'];
        _isLoading = false;
        notifyListeners();
        return true; // We return true but the UI should check twoFactorRequired
      }

      _user = UserModel.fromJson(response['user']);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
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
      _user = UserModel.fromJson(response['user']);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
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
      _error = e.toString();
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
      if (response.containsKey('user')) {
        _user = UserModel.fromJson(response['user']);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
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
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
