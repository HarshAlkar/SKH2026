import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'locale_controller.dart';

/// Shared on-device + cloud speech recognition for patient voice input.
///
/// Cloud STT is the default (`onDevice: false`) so Hindi / Marathi work on
/// phones that do not have offline language packs installed.
class VoiceRecognitionService {
  VoiceRecognitionService._();
  static final VoiceRecognitionService instance = VoiceRecognitionService._();

  final SpeechToText _speech = SpeechToText();
  List<LocaleName> _locales = [];
  bool _triedInit = false;

  void Function(String status)? _onStatus;
  void Function(String error)? _onError;

  bool get isAvailable => _speech.isAvailable;
  bool get isListening => _speech.isListening;
  List<LocaleName> get locales => List.unmodifiable(_locales);

  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) async {
    _onStatus = onStatus;
    _onError = onError;
    if (_speech.isAvailable) {
      if (_locales.isEmpty) {
        _locales = await _speech.locales();
      }
      return true;
    }
    _triedInit = true;
    final ok = await _speech.initialize(
      onStatus: (status) {
        debugPrint('STT status: $status');
        _onStatus?.call(status);
      },
      onError: (error) {
        debugPrint('STT error: ${error.errorMsg} permanent=${error.permanent}');
        _onError?.call(error.errorMsg);
      },
      finalTimeout: const Duration(seconds: 2),
    );
    if (ok) {
      _locales = await _speech.locales();
    }
    return ok;
  }

  /// Picks a locale the device actually supports (mr → hi → en).
  String resolveLocaleId([String? preferred]) {
    final wanted = (preferred ?? LocaleController.instance.speechLocaleId)
        .toLowerCase();
    if (_locales.isEmpty) {
      return preferred ?? LocaleController.instance.speechLocaleId;
    }
    for (final locale in _locales) {
      if (locale.localeId.toLowerCase() == wanted) return locale.localeId;
    }
    final prefix = wanted.split(RegExp(r'[-_]')).first;
    for (final locale in _locales) {
      if (locale.localeId.toLowerCase().startsWith(prefix)) {
        return locale.localeId;
      }
    }
    if (prefix == 'mr') {
      for (final locale in _locales) {
        if (locale.localeId.toLowerCase().startsWith('hi')) {
          return locale.localeId;
        }
      }
    }
    for (final locale in _locales) {
      if (locale.localeId.toLowerCase().startsWith('en')) {
        return locale.localeId;
      }
    }
    return _locales.first.localeId;
  }

  Future<bool> startListening({
    required void Function(String text, bool isFinal) onResult,
    void Function(String status)? onStatus,
    void Function(String error)? onError,
    String? localeId,
  }) async {
    _onStatus = onStatus;
    _onError = onError;
    final ready = await initialize(onStatus: onStatus, onError: onError);
    if (!ready) return false;
    if (_speech.isListening) {
      await _speech.stop();
    }
    try {
      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords, result.finalResult);
        },
        localeId: resolveLocaleId(localeId),
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 3),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          onDevice: false,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
          autoPunctuation: true,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('STT listen failed: $e');
      _onError?.call(e.toString());
      return false;
    }
  }

  Future<void> stop() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (e) {
      debugPrint('STT stop failed: $e');
    }
  }

  Future<void> cancel() async {
    try {
      if (_triedInit) {
        await _speech.cancel();
      }
    } catch (e) {
      debugPrint('STT cancel failed: $e');
    }
  }
}
