import 'package:flutter/foundation.dart';
import '../models/symptom_model.dart';
import '../core/services/api_service.dart';
import '../core/services/connectivity_service.dart';
import '../features/ai_symptom_checker/services/symptom_dataset_service.dart';
import '../features/ai_symptom_checker/services/symptom_ml_service.dart';
import '../features/one_health/screening_persistence.dart';

class SymptomProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final ConnectivityService _connectivity = ConnectivityService();
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

  Map<String, dynamic> _modelErrorResult(String detail) {
    return {
      'disease': 'Screening unavailable',
      'possible_condition': 'Screening could not be completed reliably',
      'disease_display': 'Screening could not be completed reliably',
      'severity': 'Unknown',
      'confidence': 0.0,
      'top_predictions': <Map<String, dynamic>>[],
      'source': 'model_error',
      'score_type': 'unavailable',
      'result_state': 'MODEL_ERROR',
      'insufficient_symptoms': false,
      'ml_error': detail,
      'message':
          'On-device screening model is unavailable. '
          'Please try again after the model is installed, or add clearer symptoms. '
          'This is not a Low-risk clearance.',
      'advice': 'Please add more symptoms or try again. Do not treat this as self-care clearance.',
      'disclaimer':
          'AI-assisted screening only. This result is not a medical diagnosis.',
    };
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

    if (kDebugMode) {
      debugPrint('SymptomProvider rawText="$symptomsText" mlInputs=$mlInputs');
    }

    // Warm / ensure load so isReady is accurate.
    await SymptomMlService.instance.tryPredict(const ['__warmup__'], language: language);

    Map<String, dynamic>? local;
    if (SymptomMlService.instance.isReady) {
      local = await SymptomMlService.instance.tryPredict(mlInputs, language: language);
    }

    var usedServerAsPrimary = false;
    if (local == null) {
      final err = SymptomMlService.instance.lastError ??
          SymptomMlService.missingMessage;
      final online = await _connectivity.isConnected();
      if (online) {
        if (kDebugMode) {
          debugPrint('SymptomProvider TFLite unavailable: $err — trying server ML');
        }
        final server = await _tryServerAnalyze(
          mlInputs: mlInputs,
          symptomsText: symptomsText,
          recognizedText: recognizedText,
          language: language,
        );
        if (server != null) {
          local = server;
          usedServerAsPrimary = true;
        } else if (mlInputs.isNotEmpty) {
          local = _modelErrorResult(err);
        } else {
          local = {
            ..._modelErrorResult(err),
            'result_state': 'INSUFFICIENT_INPUT',
            'disease': 'Not enough recognizable symptoms',
            'possible_condition': 'Not enough recognizable symptoms',
            'disease_display': 'Not enough recognizable symptoms',
          };
        }
      } else {
        if (kDebugMode) {
          debugPrint('SymptomProvider TFLite unavailable offline: $err — CSV fallback');
        }
        local = await _csvFallback(
          mlInputs: mlInputs,
          language: language,
          err: err,
        );
      }
    }

    // After the branches above, [local] is always a structured result.
    final result = local;
    if (kDebugMode) {
      debugPrint(
        'SymptomProvider result_state=${result['result_state']} '
        'source=${result['source']} disease=${result['disease']} '
        'matched=${result['matched_features']} '
        'top=${result['top_predictions']}',
      );
    }

    final state = (result['result_state'] ?? '').toString();
    final skipPersist = state == 'MODEL_ERROR' ||
        state == 'INSUFFICIENT_INPUT' ||
        result['insufficient_symptoms'] == true;

    if (!skipPersist) {
      await ScreeningPersistence.instance.enqueueHuman(
        inputType: 'symptoms',
        inputText: inputText,
        result: result,
      );
      if (!usedServerAsPrimary) {
        try {
          await _apiService.post(
            '/symptoms/analyze/',
            body: {
              'symptoms': mlInputs.isNotEmpty
                  ? mlInputs
                  : (symptomsText ?? recognizedText ?? inputText),
              if (recognizedText != null && recognizedText.isNotEmpty)
                'recognized_text': recognizedText,
              'language': language,
            },
            timeout: const Duration(seconds: 12),
          );
        } catch (_) {}
      }
    }

    _lastAnalysis = result;
    _isLoading = false;
    notifyListeners();
    return _lastAnalysis;
  }

  Future<Map<String, dynamic>> _csvFallback({
    required List<String> mlInputs,
    required String language,
    required String err,
  }) async {
    final csv = await SymptomDatasetService.instance.predict(
      mlInputs,
      language: language,
    );
    if (csv != null && csv['result_state'] != 'INSUFFICIENT_INPUT') {
      return {
        ...csv,
        'result_state': csv['result_state'] ?? 'SUCCESS_FALLBACK',
        'ml_error': err,
      };
    }
    if (csv != null && csv['result_state'] == 'INSUFFICIENT_INPUT') {
      return csv;
    }
    if (mlInputs.isNotEmpty) {
      return _modelErrorResult(err);
    }
    return {
      ..._modelErrorResult(err),
      'result_state': 'INSUFFICIENT_INPUT',
      'disease': 'Not enough recognizable symptoms',
      'possible_condition': 'Not enough recognizable symptoms',
      'disease_display': 'Not enough recognizable symptoms',
    };
  }

  Future<Map<String, dynamic>?> _tryServerAnalyze({
    required List<String> mlInputs,
    String? symptomsText,
    String? recognizedText,
    required String language,
  }) async {
    try {
      final raw = await _apiService.post(
        '/symptoms/analyze/',
        body: {
          'symptoms': mlInputs.isNotEmpty
              ? mlInputs
              : (symptomsText ?? recognizedText ?? ''),
          if (recognizedText != null && recognizedText.isNotEmpty)
            'recognized_text': recognizedText,
          'language': language,
        },
        timeout: const Duration(seconds: 12),
      );
      return _mapServerAnalysis(raw, language);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SymptomProvider server analyze failed: $e');
      }
      return null;
    }
  }

  Map<String, dynamic>? _mapServerAnalysis(dynamic raw, String language) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    if (map['error'] != null && map['disease'] == null) return null;
    final source = (map['source'] ?? 'symptom_ml').toString();
    final trained = source == 'symptom_ml' || source == 'server_ml';
    if (!trained) {
      if (kDebugMode) {
        debugPrint(
          'SymptomProvider refusing server CSV fallback while online (source=$source)',
        );
      }
      return null;
    }
    map['source'] = 'server_ml';
    map['possible_condition'] =
        map['possible_condition'] ?? map['disease_display'] ?? map['disease'];
    map['disease_display'] =
        map['disease_display'] ?? map['possible_condition'] ?? map['disease'];
    map['score_type'] = 'model_probability';
    map['result_state'] = 'SUCCESS_SERVER_ML';
    map['language'] = language;
    return map;
  }

  Future<Map<String, dynamic>?> analyzeSkin({
    String language = 'en',
    List<String>? skinSymptomTokens,
  }) async {
    _isLoading = true;
    _lastAnalysis = null;
    notifyListeners();

    if (skinSymptomTokens == null || skinSymptomTokens.isEmpty) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Select at least one skin symptom');
    }

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

    _isLoading = false;
    notifyListeners();
    throw Exception('Skin screening could not be completed. Please try again.');
  }
}
