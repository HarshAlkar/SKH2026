import 'package:flutter/material.dart';
import 'dart:io';
import '../models/symptom_model.dart';
import '../core/services/api_service.dart';
import '../core/services/storage_service.dart';
import '../features/ai_symptom_checker/services/skin_cnn_service.dart';

class SymptomProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  List<SymptomModel> _symptoms = [];
  bool _isLoading = false;
  Map<String, dynamic>? _lastAnalysis;

  List<SymptomModel> get symptoms => _symptoms;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get lastAnalysis => _lastAnalysis;

  void addSymptom(SymptomModel symptom) {
    _symptoms.add(symptom);
    notifyListeners();
  }

  Future<Map<String, dynamic>?> analyzeSymptoms({String? symptomsText, String? recognizedText}) async {
    _isLoading = true;
    _lastAnalysis = null;
    notifyListeners();
    
    try {
      final token = _storageService.getString('token');
      final response = await _apiService.post(
        '/symptoms/analyze/',
        headers: token != null ? {'Authorization': 'Token $token'} : null,
        body: {
          'symptoms': symptomsText ?? recognizedText ?? '',
          if (recognizedText != null) 'recognized_text': recognizedText,
        },
        timeout: const Duration(seconds: 60),
      );
      _lastAnalysis = response;
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      _lastAnalysis = null;
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> analyzeSkin(File imageFile) async {
    _isLoading = true;
    _lastAnalysis = null;
    notifyListeners();

    Object remoteError = SkinCnnService.missingMessage;
    try {
      final response = await _apiService.postMultipart(
        '/symptoms/analyze-skin/',
        file: imageFile,
        timeout: const Duration(seconds: 60),
      );
      _lastAnalysis = response is Map<String, dynamic>
          ? response
          : Map<String, dynamic>.from(response as Map);
      _isLoading = false;
      notifyListeners();
      return _lastAnalysis;
    } catch (e) {
      remoteError = e;
    }

    final local = await SkinCnnService.instance.tryPredict(imageFile);
    if (local != null) {
      _lastAnalysis = local;
      _isLoading = false;
      notifyListeners();
      return _lastAnalysis;
    }

    _isLoading = false;
    _lastAnalysis = null;
    notifyListeners();
    throw Exception(remoteError.toString());
  }
}
