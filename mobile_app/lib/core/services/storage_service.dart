import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    try {
      await Hive.initFlutter();
    } catch (_) {}
  }

  Future<void> saveString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  static Future<void> saveStringSync(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  static String? getStringSync(String key) {
    return _prefs.getString(key);
  }

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  static bool getBoolSync(String key, {bool defaultValue = false}) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  static Future<void> saveBoolSync(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  // Hive Box for Offline Cache
  Future<Box> openBox(String boxName) async {
    return await Hive.openBox(boxName);
  }
}
