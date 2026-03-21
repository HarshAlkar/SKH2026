import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../core/services/authentication_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthenticationService _authService = AuthenticationService();
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

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
    notifyListeners();

    try {
      final response = await _authService.login(phoneNumber, password, role);
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

  Future<bool> demoLogin(String role) async {
    _isLoading = true;
    notifyListeners();
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    _user = UserModel(
      id: 1,
      name: role == 'asha_worker' ? 'Lakshmi Devi (ASHA)' : 'Dr. Smith',
      email: role == 'asha_worker' ? 'asha@gramin.com' : 'doctor@gramin.com',
      role: role,
      phoneNumber: '9876543210',
      village: 'Gramin Village',
    );
    
    _isLoading = false;
    notifyListeners();
    return true;
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
