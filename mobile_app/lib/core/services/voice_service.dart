import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

enum VoiceState { idle, listening, speaking, loading, error }

/// Encapsulates Speech-to-Text + Text-to-Speech lifecycle.
/// Call [init] once before use.
class VoiceService {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _stt = stt.SpeechToText();

  bool _sttAvailable = false;
  VoiceState _state = VoiceState.idle;

  VoiceState get state => _state;
  bool get isListening => _state == VoiceState.listening;
  bool get isSpeaking => _state == VoiceState.speaking;
  bool get isLoading => _state == VoiceState.loading;

  // Callbacks are wired by callers
  Function(VoiceState)? onStateChange;
  Function(String)? onTranscription;
  Function(String)? onFinalTranscription;
  Function(String)? onError;

  /// Must be called before using. Returns true if STT is available.
  Future<bool> init() async {
    await _setupTts('en-IN');

    _sttAvailable = await _stt.initialize(
      onError: (err) {
        final msg = err.errorMsg;
        _setState(VoiceState.error);
        onError?.call(msg);
      },
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          if (_state == VoiceState.listening) {
            _setState(VoiceState.idle);
          }
        }
      },
    );

    _tts.setStartHandler(() => _setState(VoiceState.speaking));
    _tts.setCompletionHandler(() => _setState(VoiceState.idle));
    _tts.setCancelHandler(() => _setState(VoiceState.idle));
    _tts.setErrorHandler((msg) {
      _setState(VoiceState.idle);
      onError?.call('TTS Error: $msg');
    });

    return _sttAvailable;
  }

  Future<void> _setupTts(String locale) async {
    await _tts.setLanguage(locale);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
  }

  /// Start listening for voice input in the given locale
  Future<bool> startListening({required String sttLocale}) async {
    if (!_sttAvailable) return false;
    if (_state == VoiceState.listening) return true;

    _setState(VoiceState.listening);

    _stt.listen(
      localeId: sttLocale,
      onResult: (SpeechRecognitionResult result) {
        onTranscription?.call(result.recognizedWords);
        if (result.finalResult) {
          onFinalTranscription?.call(result.recognizedWords);
          _setState(VoiceState.idle);
        }
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 8),
      partialResults: true,
      onDevice: false, // allow online if on-device fails
      cancelOnError: false,
    );
    return true;
  }

  Future<void> stopListening() async {
    await _stt.stop();
    _setState(VoiceState.idle);
  }

  /// Speak [text] in [ttsLocale]. Returns when done.
  Future<void> speak(String text, {required String ttsLocale}) async {
    if (text.isEmpty) return;
    await stopListening();

    // Try requested locale, fall back to en-IN
    bool? avail = await _tts.isLanguageAvailable(ttsLocale);
    await _setupTts((avail ?? false) ? ttsLocale : 'en-IN');

    _setState(VoiceState.speaking);
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
    _setState(VoiceState.idle);
  }

  Future<void> dispose() async {
    await _stt.stop();
    await _tts.stop();
  }

  void _setState(VoiceState s) {
    _state = s;
    onStateChange?.call(s);
  }
}
