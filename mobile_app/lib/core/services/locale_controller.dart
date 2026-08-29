import 'package:flutter/material.dart';

import 'settings_store.dart';

/// App-wide locale. Changing language rebuilds [MaterialApp].
class LocaleController extends ChangeNotifier {
  LocaleController._();
  static final LocaleController instance = LocaleController._();

  static const supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
  ];

  static const supportedCodes = {'en', 'hi', 'mr'};

  String get languageCode {
    final code = SettingsStore.instance.language;
    return supportedCodes.contains(code) ? code : 'en';
  }

  Locale get locale => Locale(languageCode);

  bool get isHindi => languageCode == 'hi';
  bool get isMarathi => languageCode == 'mr';

  /// Speech / TTS locale. Falls back to hi-IN when mr-IN is unavailable.
  String get speechLocaleId {
    switch (languageCode) {
      case 'hi':
        return 'hi-IN';
      case 'mr':
        return 'mr-IN';
      default:
        return 'en-IN';
    }
  }

  String get ttsLocaleId => speechLocaleId;

  Future<void> setLanguage(String code) async {
    final normalized = supportedCodes.contains(code) ? code : 'en';
    if (normalized == languageCode) return;
    await SettingsStore.instance.setLanguage(normalized);
    notifyListeners();
  }
}
