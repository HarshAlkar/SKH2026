import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _appLocale = const Locale('en');
  static const String _languageKey = 'selected_language';

  Locale get appLocale => _appLocale;

  LanguageProvider() {
    _loadStoredLanguage();
  }

  Future<void> _loadStoredLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString(_languageKey);
    if (languageCode != null) {
      _appLocale = Locale(languageCode);
      notifyListeners();
    }
  }

  Future<void> changeLanguage(Locale type) async {
    if (_appLocale == type) return;

    _appLocale = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, type.languageCode);
    notifyListeners();
  }
}
