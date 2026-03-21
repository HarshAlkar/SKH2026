import 'package:flutter/material.dart';
import '../../features/doctor/services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _settingsService = SettingsService();
  
  double _fontSizeMultiplier = 1.0;
  String _languageCode = 'en'; // 'en', 'hi', 'mr'
  
  double get fontSizeMultiplier => _fontSizeMultiplier;
  String get languageCode => _languageCode;
  Locale get locale => Locale(_languageCode);

  void updateFontSize(double multiplier) {
    _fontSizeMultiplier = multiplier;
    notifyListeners();
    _settingsService.updateSettings({'font_size': multiplier});
  }

  void updateLanguage(String code) {
    _languageCode = _mapDisplayLanguageToCode(code);
    notifyListeners();
    _settingsService.updateSettings({'app_language': code});
  }

  void loadSettings(Map<String, dynamic> settings) {
    if (settings.containsKey('font_size')) {
      _fontSizeMultiplier = (settings['font_size'] ?? 1.0).toDouble();
    }
    if (settings.containsKey('app_language')) {
      _languageCode = _mapDisplayLanguageToCode(settings['app_language'] ?? 'English');
    }
    notifyListeners();
  }

  String _mapDisplayLanguageToCode(String display) {
    switch (display) {
      case 'Hindi': return 'hi';
      case 'Marathi': return 'mr';
      default: return 'en';
    }
  }

  void updateFromUser(dynamic user) {
    if (user != null) {
      _fontSizeMultiplier = user.fontSize;
      _languageCode = _mapDisplayLanguageToCode(user.appLanguage);
      notifyListeners();
    }
  }
}
