import '../services/storage_service.dart';

class AppConfig {
  static const String defaultHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: 'https://skh2026.onrender.com',
  );

  /// Gemini chat uses authenticated Django proxy — no client API key.
  static bool get hasGeminiKey => true;

  @Deprecated('Use server proxy; client keys are not used')
  static String get geminiApiKey => '';

  /// Cloud signaling origin (Render HTTPS, no :5000). Override via dart-define or saved URL.
  static const String defaultCloudSignalingUrl = String.fromEnvironment(
    'SIGNALING_URL',
    defaultValue: 'https://vitalreach-signaling.onrender.com',
  );

  static const int apiPort = 8000;
  static const int signalingPort = 5000;
  static const String hostKey = 'server_host';
  static const String signalingKey = 'signaling_url';

  static const String turnUrl = String.fromEnvironment('TURN_URL');
  static const String turnUser = String.fromEnvironment('TURN_USER');
  static const String turnPass = String.fromEnvironment('TURN_PASS');

  static String get host {
    final saved = StorageService.getStringSync(hostKey);
    if (saved != null && saved.trim().isNotEmpty) {
      return saved.trim();
    }
    return defaultHost;
  }

  static Future<void> setHost(String value) async {
    await StorageService.saveStringSync(hostKey, value.trim());
  }

  static Future<void> setSignalingUrl(String value) async {
    await StorageService.saveStringSync(signalingKey, value.trim());
  }

  static Future<void> clearSignalingUrl() async {
    await StorageService.saveStringSync(signalingKey, '');
  }

  static bool get _isAbsolute {
    final value = host.toLowerCase();
    return value.startsWith('http://') || value.startsWith('https://');
  }

  static bool get isCloudHost {
    if (!_isAbsolute) return false;
    final h = Uri.tryParse(origin)?.host.toLowerCase() ?? '';
    return h.contains('onrender.com') || h.contains('railway.app') || h.contains('fly.dev');
  }

  static String get origin {
    final raw = host.replaceAll(RegExp(r'/$'), '');
    if (_isAbsolute) return raw;
    return 'http://$raw:$apiPort';
  }

  static String get baseUrl => '$origin/api';

  static String get displayHost {
    if (_isAbsolute) return origin;
    return '$host:$apiPort';
  }

  static String get signalingServerUrl {
    final saved = StorageService.getStringSync(signalingKey);
    if (saved != null && saved.trim().isNotEmpty) {
      return saved.trim().replaceAll(RegExp(r'/$'), '');
    }
    if (defaultCloudSignalingUrl.isNotEmpty && isCloudHost) {
      return defaultCloudSignalingUrl.replaceAll(RegExp(r'/$'), '');
    }
    if (_isAbsolute) {
      final uri = Uri.parse(origin);
      // Never append :5000 to cloud HTTPS hosts (Render/Railway expose 443 only).
      if (uri.scheme == 'https' || isCloudHost) {
        if (defaultCloudSignalingUrl.isNotEmpty) {
          return defaultCloudSignalingUrl.replaceAll(RegExp(r'/$'), '');
        }
        return '${uri.scheme}://${uri.host}';
      }
      return 'http://${uri.host}:$signalingPort';
    }
    return 'http://$host:$signalingPort';
  }

  static List<Map<String, dynamic>> get iceServers {
    final servers = <Map<String, dynamic>>[
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun.cloudflare.com:3478'},
    ];
    if (turnUrl.isNotEmpty) {
      servers.add({
        'urls': turnUrl,
        'username': turnUser,
        'credential': turnPass,
      });
    }
    return servers;
  }
}
