import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// AES-256-GCM encryption for sensitive offline payloads.
/// This is ENCRYPTION (confidentiality), not hashing.
class SecurePayloadCrypto {
  SecurePayloadCrypto._();
  static final SecurePayloadCrypto instance = SecurePayloadCrypto._();

  static const _keyStorageKey = 'vr_outbox_aes_key_v1';
  static const _prefix = 'vr1:';

  final _storage = const FlutterSecureStorage();
  final _algorithm = AesGcm.with256bits();
  SecretKey? _cachedKey;

  Future<SecretKey> _key() async {
    if (_cachedKey != null) return _cachedKey!;
    var b64 = await _storage.read(key: _keyStorageKey);
    if (b64 == null || b64.isEmpty) {
      final raw = List<int>.generate(32, (_) => Random.secure().nextInt(256));
      b64 = base64Encode(raw);
      await _storage.write(key: _keyStorageKey, value: b64);
    }
    _cachedKey = SecretKey(base64Decode(b64));
    return _cachedKey!;
  }

  Future<String?> encryptJson(dynamic value) async {
    if (value == null) return null;
    final plain = utf8.encode(jsonEncode(value));
    final secretKey = await _key();
    final nonce = _algorithm.newNonce();
    final box = await _algorithm.encrypt(
      plain,
      secretKey: secretKey,
      nonce: nonce,
    );
    final packed = <int>[
      ...box.nonce,
      ...box.cipherText,
      ...box.mac.bytes,
    ];
    return '$_prefix${base64Encode(packed)}';
  }

  Future<dynamic> decryptJson(String? stored) async {
    if (stored == null || stored.isEmpty) return null;
    if (!stored.startsWith(_prefix)) {
      // Legacy plaintext rows (pre-hardening)
      return jsonDecode(stored);
    }
    final packed = base64Decode(stored.substring(_prefix.length));
    if (packed.length < 12 + 16) {
      throw StateError('Corrupt encrypted payload');
    }
    final nonce = packed.sublist(0, 12);
    final mac = packed.sublist(packed.length - 16);
    final cipherText = packed.sublist(12, packed.length - 16);
    final secretKey = await _key();
    final clear = await _algorithm.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
      secretKey: secretKey,
    );
    return jsonDecode(utf8.decode(clear));
  }

  /// Encrypt arbitrary UTF-8 string (emergency packets, etc.).
  Future<String> encryptString(String plain) async {
    return (await encryptJson({'v': plain}))!;
  }

  Future<String> decryptString(String stored) async {
    final decoded = await decryptJson(stored);
    if (decoded is Map && decoded['v'] is String) {
      return decoded['v'] as String;
    }
    return stored;
  }
}
