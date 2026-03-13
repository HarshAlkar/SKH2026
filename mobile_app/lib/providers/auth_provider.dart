import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    _user = UserModel(
      id: '1',
      name: 'John Doe',
      email: email,
      role: 'villager',
      phoneNumber: '1234567890',
    );

    _isLoading = false;
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
