import '../config/app_config.dart';

String friendlyNetworkError(Object error) {
  var message = error.toString();
  if (message.startsWith('Exception: ')) {
    message = message.substring(11);
  }

  final lower = message.toLowerCase();
  if (lower.contains('cleartext')) {
    return 'This device blocked HTTP. Rebuild the app after the latest network update.';
  }
  if (lower.contains('timed out') || lower.contains('timeout')) {
    return 'Cannot reach the server at ${AppConfig.host}:${AppConfig.apiPort}. Check the Server host and that Django is running.';
  }
  if (lower.contains('connection refused') ||
      lower.contains('socketexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('network is unreachable') ||
      lower.contains('connection failed') ||
      lower.contains('connection reset')) {
    return 'Cannot connect to ${AppConfig.host}:${AppConfig.apiPort}. For the emulator use 10.0.2.2. For a phone, use this PC\'s Wi-Fi IP and run Django with 0.0.0.0:8000.';
  }
  return message;
}
