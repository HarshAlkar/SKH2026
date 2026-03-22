import 'package:flutter/material.dart';
import 'package:hs053/core/services/voice_assistant_service.dart';
import 'package:hs053/shared/providers/symptom_provider.dart';

enum AssistantState { idle, listening, processing, speaking, error }

class LanguageOption {
  final String name;
  final String code; // Locale ID for STT/TTS
  final String displayShort;

  LanguageOption({
    required this.name,
    required this.code,
    required this.displayShort,
  });
}

class VoiceAssistantProvider extends ChangeNotifier {
  final VoiceAssistantService _voiceService = VoiceAssistantService();
  final List<LanguageOption> _languages = [
    LanguageOption(name: 'English', code: 'en-IN', displayShort: 'EN'),
    LanguageOption(name: 'Hindi', code: 'hi-IN', displayShort: 'HI'),
    LanguageOption(name: 'Marathi', code: 'mr-IN', displayShort: 'MR'),
  ];
  
  late LanguageOption _currentLanguage;
  AssistantState _state = AssistantState.idle;
  String _transcribedText = "";
  String _responseMessage = "";
  String _lastError = "";
  bool _isProcessingSet = false;

  AssistantState get state => _state;
  LanguageOption get currentLanguage => _currentLanguage;
  List<LanguageOption> get languages => _languages;
  String get transcribedText => _transcribedText;
  String get responseMessage => _responseMessage;
  String get lastError => _lastError;

  VoiceAssistantProvider() {
    _currentLanguage = _languages[1]; // Default to Hindi
    _voiceService.setCompletionHandler(() {
      _state = AssistantState.idle;
      _isProcessingSet = false;
      notifyListeners();
    });
  }

  void setLanguage(LanguageOption lang) {
    _currentLanguage = lang;
    notifyListeners();
  }

  Future<void> toggleListening(SymptomProvider symptomProvider) async {
    if (_state == AssistantState.listening) {
      await _stopAndAnalyze(symptomProvider);
    } else if (_state == AssistantState.idle || _state == AssistantState.error) {
      await _startListening(symptomProvider);
    } else if (_state == AssistantState.speaking) {
      reset();
    }
  }

  Future<void> _startListening(SymptomProvider symptomProvider) async {
    bool canListen = await _voiceService.init();
    if (!canListen) {
      _setError("Microphone permission required.");
      return;
    }

    _state = AssistantState.listening;
    _transcribedText = "";
    _responseMessage = "";
    _lastError = "";
    _isProcessingSet = false;
    notifyListeners();

    try {
      await _voiceService.startListening(
        languageCode: _currentLanguage.code,
        onResult: (text) {
          if (_state == AssistantState.listening) {
            _transcribedText = text;
            notifyListeners();
          }
        },
        onDone: () {
          if (_state == AssistantState.listening && !_isProcessingSet) {
            _stopAndAnalyze(symptomProvider);
          }
        },
      );
    } catch (e) {
      _setError("Listening failed: $e");
    }
  }

  Future<void> _stopAndAnalyze(SymptomProvider symptomProvider) async {
    if (_isProcessingSet) return;
    _isProcessingSet = true;
    
    _state = AssistantState.processing;
    notifyListeners();

    try {
      await _voiceService.stopListening();
      
      // Delay to ensure all partial results are processed and final result is stable
      await Future.delayed(const Duration(milliseconds: 1000));

      if (_transcribedText.trim().isEmpty) {
        _handleFailure(_currentLanguage.code == 'hi-IN' ? "मैंने कुछ नहीं सुना। फिर से प्रयास करें।" : "I didn't hear anything. Please try again.");
        return;
      }

      final analysis = await symptomProvider.analyzeSymptoms(
        recognizedText: _transcribedText,
      );

      if (analysis != null) {
        String disease = analysis['disease'] ?? "General symptoms";
        String severity = analysis['severity'] ?? "Normal";
        
        _responseMessage = _generateResponse(disease, severity);
        _state = AssistantState.speaking;
        notifyListeners();
        
        await _voiceService.speak(_responseMessage, _currentLanguage.code);
      } else {
        _handleFailure(_currentLanguage.code == 'hi-IN' ? "मुझे समझ नहीं आया। क्या आप फिर से बता सकते हैं?" : "I couldn't process that. Could you repeat?");
      }
    } catch (e) {
      _handleFailure("Error: $e");
    }
  }

  void _handleFailure(String msg) async {
    _responseMessage = msg;
    _state = AssistantState.speaking;
    notifyListeners();
    await _voiceService.speak(_responseMessage, _currentLanguage.code);
  }

  String _generateResponse(String disease, String severity) {
    if (_currentLanguage.code == 'hi-IN') {
      return "एनालिसिस के अनुसार, यह $disease के लक्षण हो सकते हैं। आपकी स्थिति $severity है। उचित डॉक्टरी सलाह लें।";
    } else if (_currentLanguage.code == 'mr-IN') {
      return "तपासणीनुसार, हे $disease चे लक्षण असू शकतात. तुमची स्थिती $severity आहे. डॉक्टरांचा सल्ला घ्या.";
    } else {
      return "Based on your symptoms, it could be $disease. The severity level is $severity. Please consult a doctor.";
    }
  }

  void _setError(String msg) async {
    _state = AssistantState.error;
    _lastError = msg;
    notifyListeners();
    
    if (!msg.contains("permission")) {
      await _voiceService.speak(msg, _currentLanguage.code);
    }

    Future.delayed(const Duration(seconds: 4), () {
      if (_state == AssistantState.error) {
        reset();
      }
    });
  }

  void reset() {
    _voiceService.stopSpeaking();
    _voiceService.stopListening();
    _state = AssistantState.idle;
    _isProcessingSet = false;
    _transcribedText = "";
    _responseMessage = "";
    _lastError = "";
    notifyListeners();
  }
}
