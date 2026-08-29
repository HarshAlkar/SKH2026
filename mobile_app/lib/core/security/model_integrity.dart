import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// SHA-256 integrity verification for on-device TFLite models.
/// SHA-256 is a HASH for integrity — it is NOT encryption.
class ModelIntegrity {
  ModelIntegrity._();

  static const manifestAsset = 'assets/models/model_integrity.json';

  static Future<Map<String, dynamic>> _loadManifest() async {
    try {
      final raw = await rootBundle.loadString(manifestAsset);
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// Returns true if the asset bytes match the expected SHA-256 (when set).
  /// If expected hash is empty/missing, verification is skipped (dev builds).
  static Future<bool> verifyAsset(String assetPath) async {
    final manifest = await _loadManifest();
    final models = manifest['models'];
    if (models is! Map) return true;
    final entry = models[assetPath.split('/').last] ?? models[assetPath];
    if (entry is! Map) return true;
    final expected = (entry['sha256'] ?? '').toString().trim().toLowerCase();
    if (expected.isEmpty) {
      debugPrint('ModelIntegrity: no expected hash for $assetPath (skipped)');
      return true;
    }
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    final digest = sha256.convert(bytes).toString();
    if (digest != expected) {
      debugPrint('ModelIntegrity FAIL $assetPath expected=$expected got=$digest');
      return false;
    }
    return true;
  }

  static String hashBytes(List<int> bytes) => sha256.convert(bytes).toString();
}
