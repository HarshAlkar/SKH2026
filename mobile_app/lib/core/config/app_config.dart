import '../services/storage_service.dart';

class AppConfig {
  static const String defaultHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: 'http://127.0.0.1:8000',
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

  static bool get _isAbsolute {
    final value = host.toLowerCase();
    return value.startsWith('http://') || value.startsWith('https://');
  }

  static String get origin {
    var raw = host.trim().replaceAll(RegExp(r'/$'), '');
    if (_isAbsolute) return raw;
    if (raw.contains(':')) return 'http://$raw';
    return 'http://$raw:$apiPort';
  }

  static String get baseUrl => '$origin/api';

  static String get displayHost {
    if (_isAbsolute) return origin;
    if (host.contains(':')) return host;
    return '$host:$apiPort';
  }

  static String get signalingServerUrl {
    final saved = StorageService.getStringSync(signalingKey);
    if (saved != null && saved.trim().isNotEmpty) {
      return saved.trim().replaceAll(RegExp(r'/$'), '');
    }
    if (_isAbsolute) {
      final uri = Uri.parse(origin);
      final scheme = uri.scheme == 'https' ? 'https' : 'http';
      return '$scheme://${uri.host}:$signalingPort';
    }
    return 'http://$host:$signalingPort';
  }

  static List<Map<String, dynamic>> get iceServers {
    final servers = <Map<String, dynamic>>[
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
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
