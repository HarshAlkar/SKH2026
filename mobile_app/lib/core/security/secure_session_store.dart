import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/storage_service.dart';

/// Auth token + session JSON in platform secure storage (not SharedPreferences).
class SecureSessionStore {
  SecureSessionStore._();
  static final SecureSessionStore instance = SecureSessionStore._();

  static const tokenKey = 'token';
  static const userDataKey = 'user_data';

  final _secure = const FlutterSecureStorage();
  final _prefs = StorageService();

  Future<String?> readToken() async {
    var token = await _secure.read(key: tokenKey);
    if (token != null && token.isNotEmpty) return token;
    // Migrate legacy SharedPreferences token once
    final legacy = _prefs.getString(tokenKey);
    if (legacy != null && legacy.isNotEmpty) {
      await _secure.write(key: tokenKey, value: legacy);
      await _prefs.remove(tokenKey);
      return legacy;
    }
    return null;
  }

  Future<String?> readUserDataJson() async {
    var raw = await _secure.read(key: userDataKey);
    if (raw != null && raw.isNotEmpty) return raw;
    final legacy = _prefs.getString(userDataKey);
    if (legacy != null && legacy.isNotEmpty) {
      await _secure.write(key: userDataKey, value: legacy);
      await _prefs.remove(userDataKey);
      return legacy;
    }
    return null;
  }

  Future<void> writeSession({required String token, required String userDataJson}) async {
    await _secure.write(key: tokenKey, value: token);
    await _secure.write(key: userDataKey, value: userDataJson);
    await _prefs.remove(tokenKey);
    await _prefs.remove(userDataKey);
  }

  Future<void> clearSession() async {
    await _secure.delete(key: tokenKey);
    await _secure.delete(key: userDataKey);
    await _prefs.remove(tokenKey);
    await _prefs.remove(userDataKey);
  }
}
