import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/services/language_manager.dart';
import '../../../core/constants/offline_ai_data.dart';
import '../../../models/symptom_analysis_result_model.dart';

class AIService {
  final ApiService _apiService = ApiService();
  final VoiceService _voiceService = VoiceService();
  final Connectivity _connectivity = Connectivity();

  VoiceService get voiceService => _voiceService;

  Future<void> init() async {
    await _voiceService.init();
  }

  /// Processes input and returns a localized response.
  Future<String> getAIResponse(String input, {required String lang}) async {
    final List<ConnectivityResult> connectivityResult = await _connectivity.checkConnectivity();
    final bool isOffline = connectivityResult.contains(ConnectivityResult.none);

    if (isOffline) {
      return OfflineAIData.getOfflineResponse(input, lang);
    } else {
      try {
        final response = await _apiService.post('/symptoms/analyze/', body: {
          'symptoms': input,
          'language': lang,
          'is_voice': true
        });
        
        if (response['response'] != null) {
          return response['response'];
        }
        return OfflineAIData.getOfflineResponse(input, lang);
      } catch (e) {
        return OfflineAIData.getOfflineResponse(input, lang);
      }
    }
  }

  Future<void> speak(String text, {String? ttsLocale}) async {
    await _voiceService.speak(text, ttsLocale: ttsLocale ?? 'en-IN');
  }

  Future<void> stopSpeaking() async {
    await _voiceService.stopSpeaking();
  }

  Future<void> stopListening() async {
    await _voiceService.stopListening();
  }

  void dispose() {
    _voiceService.dispose();
  }

  /// Specialized method for symptom analysis (used in SymptomCheckerScreen)
  Future<SymptomAnalysisResultModel> analyzeSymptoms(String symptomsText, String langCode) async {
    final List<ConnectivityResult> connectivityResult = await _connectivity.checkConnectivity();
    final bool isOffline = connectivityResult.contains(ConnectivityResult.none);

    if (isOffline) {
      final response = OfflineAIData.getOfflineResponse(symptomsText, langCode);
      return SymptomAnalysisResultModel(
        disease: _guessDisease(symptomsText, langCode),
        severity: _guessSeverity(symptomsText),
        recommendation: response,
        alertSent: false,
        symptoms: [],
      );
    } else {
      final response = await _apiService.post('/symptoms/analyze/', body: {
        'symptoms': symptomsText,
        'language': langCode,
      });
      return SymptomAnalysisResultModel.fromJson(response);
    }
  }

  String _guessDisease(String input, String lang) {
    input = input.toLowerCase();
    if (input.contains('fever') || input.contains('ताप') || input.contains('बुखार')) return 'Viral Fever';
    if (input.contains('headache') || input.contains('डोकेदुखी') || input.contains('सिरदर्द')) return 'Migraine';
    if (input.contains('cough') || input.contains('खोकला') || input.contains('खांसी')) return 'Common Cold';
    return 'Undetermined';
  }

  String _guessSeverity(String input) {
    if (input.contains('severe') || input.contains('chest pain') || input.contains('unconscious')) return 'High';
    if (input.contains('moderate') || input.contains('pain')) return 'Moderate';
    return 'Low';
  }
}
