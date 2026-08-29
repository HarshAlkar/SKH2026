import 'package:flutter/material.dart';
import 'dart:io';
import '../models/symptom_model.dart';
import '../core/services/api_service.dart';
import '../core/services/storage_service.dart';
import '../core/utils/network_errors.dart';
import '../features/ai_symptom_checker/services/skin_cnn_service.dart';
import '../features/ai_symptom_checker/services/symptom_dataset_service.dart';
import '../features/ai_symptom_checker/services/symptom_ml_service.dart';
import '../features/one_health/screening_persistence.dart';

class SymptomProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final List<SymptomModel> _symptoms = [];
  bool _isLoading = false;
  Map<String, dynamic>? _lastAnalysis;

  List<SymptomModel> get symptoms => _symptoms;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get lastAnalysis => _lastAnalysis;

  void addSymptom(SymptomModel symptom) {
    _symptoms.add(symptom);
    notifyListeners();
  }

  /// [selectedTokens] = chip tokens + confirmed free-text extractions (already merged).
  Future<Map<String, dynamic>?> analyzeSymptoms({
    String? symptomsText,
    String? recognizedText,
    String language = 'en',
    List<String>? selectedTokens,
  }) async {
    _isLoading = true;
    _lastAnalysis = null;
    notifyListeners();

    final localInputs = <String>[
      if (selectedTokens != null && selectedTokens.isNotEmpty) ...selectedTokens,
      if (symptomsText != null && symptomsText.trim().isNotEmpty)
        symptomsText.trim(),
      if (recognizedText != null && recognizedText.trim().isNotEmpty)
        recognizedText.trim(),
    ];
    final inputText = localInputs.join(', ');

    // Prefer chip/confirmed tokens alone for the multi-hot vector when provided.
    final mlInputs = (selectedTokens != null && selectedTokens.isNotEmpty)
        ? selectedTokens
        : localInputs;

    Map<String, dynamic>? local =
        await SymptomMlService.instance.tryPredict(mlInputs, language: language);

    if (local == null) {
      final csv = await SymptomDatasetService.instance.predict(
        mlInputs,
        language: language,
      );
      if (csv != null) {
        local = {
          ...csv,
          'ml_error': SymptomMlService.instance.lastError,
        };
      }
    }

    if (local != null) {
      if (local['insufficient_symptoms'] == true) {
        _lastAnalysis = local;
        _isLoading = false;
        notifyListeners();
        return _lastAnalysis;
      }

      await ScreeningPersistence.instance.enqueueHuman(
        inputType: 'symptoms',
        inputText: inputText,
        result: local,
      );
      try {
        final token = _storageService.getString('token');
        await _apiService.post(
          '/symptoms/analyze/',
          headers: token != null ? {'Authorization': 'Token $token'} : null,
          body: {
            'symptoms': symptomsText ?? recognizedText ?? inputText,
            if (recognizedText != null) 'recognized_text': recognizedText,
            'language': language,
          },
          timeout: const Duration(seconds: 12),
        );
      } catch (_) {}

      _lastAnalysis = local;
      _isLoading = false;
      notifyListeners();
      return _lastAnalysis;
    }

    try {
      final token = _storageService.getString('token');
      final response = await _apiService.post(
        '/symptoms/analyze/',
        headers: token != null ? {'Authorization': 'Token $token'} : null,
        body: {
          'symptoms': symptomsText ?? recognizedText ?? '',
          if (recognizedText != null) 'recognized_text': recognizedText,
          'language': language,
        },
        timeout: const Duration(seconds: 60),
      );
      final map = response is Map<String, dynamic>
          ? response
          : Map<String, dynamic>.from(response as Map);
      map['source'] = map['source'] ?? 'server_ml';
      map['score_type'] = map['score_type'] ?? 'model_probability';
      _lastAnalysis = map;
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      _lastAnalysis = null;
      notifyListeners();
      throw Exception(friendlyNetworkError(e, kind: NetworkErrorKind.ai));
    }
  }

  Future<Map<String, dynamic>?> analyzeSkin(
    File? imageFile, {
    String language = 'en',
    List<String>? skinSymptomTokens,
  }) async {
    _isLoading = true;
    _lastAnalysis = null;
    notifyListeners();

    if (imageFile != null) {
      final local = await SkinCnnService.instance.tryPredict(imageFile);
      if (local != null) {
        await ScreeningPersistence.instance.enqueueHuman(
          inputType: 'image',
          inputText: 'skin_photo:${imageFile.path.split(RegExp(r"[\\/]")).last}',
          result: local,
        );
        try {
          await _apiService.postMultipart(
            '/symptoms/analyze-skin/',
            file: imageFile,
            fields: {'language': language},
            timeout: const Duration(seconds: 12),
          );
        } catch (_) {}
        _lastAnalysis = local;
        _isLoading = false;
        notifyListeners();
        return _lastAnalysis;
      }

      try {
        final response = await _apiService.postMultipart(
          '/symptoms/analyze-skin/',
          file: imageFile,
          fields: {'language': language},
          timeout: const Duration(seconds: 60),
        );
        _lastAnalysis = response is Map<String, dynamic>
            ? response
            : Map<String, dynamic>.from(response as Map);
        _isLoading = false;
        notifyListeners();
        return _lastAnalysis;
      } catch (_) {}
    }

    if (skinSymptomTokens != null && skinSymptomTokens.isNotEmpty) {
      final dataset = await SymptomMlService.instance.tryPredict(
            skinSymptomTokens,
            language: language,
          ) ??
          await SymptomDatasetService.instance.predict(
            skinSymptomTokens,
            skinOnly: true,
            language: language,
          );
      if (dataset != null) {
        await ScreeningPersistence.instance.enqueueHuman(
          inputType: 'symptoms',
          inputText: skinSymptomTokens.join(', '),
          result: dataset,
        );
        _lastAnalysis = dataset;
        _isLoading = false;
        notifyListeners();
        return _lastAnalysis;
      }
    }

    _isLoading = false;
    notifyListeners();
    throw Exception(SkinCnnService.missingMessage);
  }
}
