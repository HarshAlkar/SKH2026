import '../config/app_config.dart';

enum NetworkErrorKind { generic, ai }

String friendlyNetworkError(
  Object error, {
  NetworkErrorKind kind = NetworkErrorKind.generic,
}) {
  var message = error.toString();
  if (message.startsWith('Exception: ')) {
    message = message.substring(11);
  }

  final lower = message.toLowerCase();
  if (lower.contains('cleartext')) {
    return 'This device blocked HTTP. Rebuild the app after the latest network update.';
  }
  if (lower.contains('timed out') ||
      lower.contains('timeout') ||
      lower.contains('took too long')) {
    if (kind == NetworkErrorKind.ai) {
      return 'The AI took too long to respond. Keep Django running and tap Analyze again.';
    }
    return 'The server took too long to respond (${AppConfig.displayHost}). Make sure Django is running and try again.';
  }
  if (lower.contains('connection refused') ||
      lower.contains('socketexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('network is unreachable') ||
      lower.contains('connection failed') ||
      lower.contains('connection reset')) {
    return 'Cannot connect to ${AppConfig.displayHost}. Use 10.0.2.2 for the emulator, your PC Wi-Fi IP for a phone, or the HTTPS cloud URL.';
  }
  return message;
}
