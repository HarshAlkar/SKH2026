import '../services/storage_service.dart';

class AppConfig {
  static const String defaultHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: '10.0.2.2',
  );
  static const int apiPort = 8000;
  static const int signalingPort = 5000;
  static const String hostKey = 'server_host';

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

  static String get baseUrl => 'http://$host:$apiPort/api';

  static String get signalingServerUrl => 'http://$host:$signalingPort';

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
