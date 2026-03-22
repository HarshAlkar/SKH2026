import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceAssistantService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isSpeechInitialized = false;
  Function()? _onSpeechDone;

  Future<bool> init() async {
    if (_isSpeechInitialized) return true;
    
    try {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        debugPrint('Voice Service: Mic permission denied');
        return false;
      }

      _isSpeechInitialized = await _speech.initialize(
        onStatus: (status) => debugPrint('STT Status: $status'),
        onError: (error) => debugPrint('STT Error: $error'),
      );
      
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);
      
      _tts.setCompletionHandler(() {
        if (_onSpeechDone != null) _onSpeechDone!();
      });

      return _isSpeechInitialized;
    } catch (e) {
      debugPrint('Voice Service init error: $e');
      return false;
    }
  }

  void setCompletionHandler(Function() callback) {
    _onSpeechDone = callback;
  }

  Future<void> startListening({
    required Function(String) onResult,
    required String languageCode,
    required Function() onDone,
  }) async {
    if (!_isSpeechInitialized) {
      bool success = await init();
      if (!success) return;
    }

    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
        // Only trigger completion when STT explicitly marks the result as final
        if (result.finalResult) {
          debugPrint('STT: Final Result Received');
          onDone();
        }
      },
      localeId: languageCode,
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 3), // Extended silence detection
      partialResults: true,
      cancelOnError: true,
      listenMode: stt.ListenMode.search, // Better for descriptive commands
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  Future<void> cancelListening() async {
    await _speech.cancel();
  }

  Future<void> speak(String text, String languageCode) async {
    try {
      await _tts.setLanguage(languageCode);
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS Speak Error: $e');
    }
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  bool get isListening => _speech.isListening;
}
