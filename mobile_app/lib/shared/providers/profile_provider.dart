import 'package:flutter/material.dart';
import 'package:hs053/core/services/profile_service.dart';
import 'package:hs053/shared/providers/auth_provider.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  bool _isLoading = false;
  String? _error;
  List<dynamic> _familyMembers = [];
  Map<String, dynamic>? _emergencyDetails;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic> get familyMembers => _familyMembers;
  Map<String, dynamic>? get emergencyDetails => _emergencyDetails;

  Future<void> fetchFamilyMembers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _familyMembers = await _profileService.getFamilyMembers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> addFamilyMember(String name, String relation, String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _profileService.addFamilyMember({
        'name': name,
        'relationship': relation,
        'phone_number': phone,
      });
      await fetchFamilyMembers();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteFamilyMember(int id) async {
    try {
      await _profileService.deleteFamilyMember(id);
      await fetchFamilyMembers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEmergencyInfo({
    String? bloodGroup,
    String? allergies,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Need patient ID for full REST update or use custom endpoint
      // Assuming existing auth user's profile is handled by me/
      await _profileService.updateProfile({
        if (bloodGroup != null) 'blood_group': bloodGroup,
        if (allergies != null) 'allergies': allergies,
        if (notes != null) 'emergency_notes': notes,
      });
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> lookupByQR(String abhaId) async {
    _isLoading = true;
    _error = null;
    _emergencyDetails = null;
    notifyListeners();

    try {
      _emergencyDetails = await _profileService.fetchEmergencyDetails(abhaId);
      _isLoading = false;
      notifyListeners();
      return _emergencyDetails;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> lookupClinicalByQR(String abhaId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final details = await _profileService.fetchClinicalDetails(abhaId);
      _isLoading = false;
      notifyListeners();
      return details;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
