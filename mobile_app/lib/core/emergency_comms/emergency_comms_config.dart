import '../services/settings_store.dart';
import 'emergency_mode.dart';

class EmergencyCommsConfig {
  EmergencyCommsConfig._();

  static const String defaultSsid = 'VitalReach-EMG';
  static const String defaultApPassword = 'vitalreach';
  static const String defaultGatewayHost = '192.168.4.1';
  static const int gatewayPort = 80;
  static const int ttlSeconds = 300;
  static const int maxRetries = 5;
  static const Duration ackTimeout = Duration(seconds: 3);
  static const Duration retryBackoff = Duration(seconds: 2);
  static const Duration inboxPollInterval = Duration(seconds: 2);
  static const Duration httpTimeout = Duration(seconds: 4);

  static const String _compileMode = String.fromEnvironment(
    'EMERGENCY_MODE',
    defaultValue: 'MOCK',
  );
  static const String _compileGateway = String.fromEnvironment(
    'EMERGENCY_GATEWAY',
    defaultValue: defaultGatewayHost,
  );

  static EmergencyMode get mode {
    final saved = SettingsStore.instance.emergencyMode;
    if (saved != null && saved.trim().isNotEmpty) {
      return EmergencyMode.parse(saved);
    }
    return EmergencyMode.parse(_compileMode);
  }

  static String get gatewayHost {
    final saved = SettingsStore.instance.emergencyGatewayHost;
    if (saved != null && saved.trim().isNotEmpty) {
      return saved.trim();
    }
    return _compileGateway.trim().isEmpty ? defaultGatewayHost : _compileGateway.trim();
  }

  static String get gatewayOrigin {
    final raw = gatewayHost.replaceAll(RegExp(r'/$'), '');
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.contains(':')) return 'http://$raw';
    return 'http://$raw:$gatewayPort';
  }

  static Future<void> setMode(EmergencyMode value) {
    return SettingsStore.instance.setEmergencyMode(value.wireName);
  }

  static Future<void> setGatewayHost(String value) {
    return SettingsStore.instance.setEmergencyGatewayHost(value.trim());
  }
}
