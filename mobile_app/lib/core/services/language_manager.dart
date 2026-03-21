import 'package:flutter/material.dart';
import '../services/storage_service.dart';

/// Manages the app language (English / Hindi / Marathi)
/// Persists selection between sessions using StorageService.
class LanguageManager extends ChangeNotifier {
  static const String _key = 'app_language';
  static const String kEnglish = 'English';
  static const String kHindi = 'Hindi';
  static const String kMarathi = 'Marathi';

  String _language = kEnglish;

  String get language => _language;
  String get currentLang => _language;

  /// BCP-47 locale for speech_to_text (underscore format)
  String get sttLocale {
    switch (_language) {
      case kHindi:
        return 'hi_IN';
      case kMarathi:
        return 'mr_IN';
      default:
        return 'en_IN';
    }
  }

  /// BCP-47 locale for flutter_tts (hyphen format)
  String get ttsLocale {
    switch (_language) {
      case kHindi:
        return 'hi-IN';
      case kMarathi:
        return 'mr-IN';
      default:
        return 'en-IN';
    }
  }

  /// Short code for API language param
  String get langCode {
    switch (_language) {
      case kHindi:
        return 'hi';
      case kMarathi:
        return 'mr';
      default:
        return 'en';
    }
  }

  LanguageManager() {
    _loadSaved();
  }

  void _loadSaved() {
    final saved = StorageService().getString(_key);
    if (saved != null &&
        [kEnglish, kHindi, kMarathi].contains(saved)) {
      _language = saved;
    }
  }

  Future<void> setLanguage(String lang) async {
    if (_language == lang) return;
    _language = lang;
    await StorageService().saveString(_key, lang);
    notifyListeners();
  }
}
