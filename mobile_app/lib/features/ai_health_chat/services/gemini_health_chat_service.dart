import '../../../core/services/api_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../one_health/escalation_policy.dart';
import '../models/screening_chat_context.dart';

/// AI health chat via authenticated VitalReach backend → Gemini.
/// The Gemini API key never ships in the Flutter client.
class GeminiHealthChatService {
  GeminiHealthChatService._();
  static final GeminiHealthChatService instance = GeminiHealthChatService._();

  ScreeningChatContext? _context;
  final ApiService _api = ApiService();
  final List<Map<String, String>> _turns = [];
  bool? _serverConfigured;

  /// True only after a successful status probe (or unknown until checked).
  bool get isConfigured => _serverConfigured ?? true;

  Future<bool> get isOnline async => ConnectivityService().isConnected();

  void reset() {
    _context = null;
    _turns.clear();
    _serverConfigured = null;
  }

  String _domainKey(ScreeningDomain domain) {
    return switch (domain) {
      ScreeningDomain.human => 'human',
      ScreeningDomain.skin => 'skin',
      ScreeningDomain.livestock => 'livestock',
      ScreeningDomain.child => 'child',
    };
  }

  /// SAFE probe — never receives the API key.
  Future<bool> checkServerConfigured() async {
    try {
      final response = await _api.get('/ai/status/');
      if (response is Map) {
        final ok = response['gemini_configured'] == true;
        _serverConfigured = ok;
        return ok;
      }
    } catch (_) {
      // If status endpoint missing on older servers, allow chat attempt.
      _serverConfigured = null;
    }
    return true;
  }

  Future<void> startSession(ScreeningChatContext context) async {
    _context = context;
    _turns.clear();
    await checkServerConfigured();
    if (_serverConfigured == false) {
      throw StateError(
        'AI assistant is not configured on the server. '
        'Set GEMINI_API_KEY in the Django environment (never in the Flutter app).',
      );
    }
  }

  Future<String> sendMessage(String userText) async {
    final text = userText.trim();
    if (text.isEmpty) return '';
    if (!await isOnline) {
      throw StateError(
        'AI chat requires an internet connection, but your screening result '
        'and recommended next steps are available offline.',
      );
    }
    final ctx = _context;
    if (ctx == null) {
      throw StateError('Chat session was not started.');
    }

    final prompt = StringBuffer()
      ..writeln('Screening context (decision-support only):')
      ..writeln(ctx.toPromptBlock())
      ..writeln()
      ..writeln('User question:')
      ..writeln(text);

    try {
      final response = await _api.post(
        '/ai/gemini-chat/',
        body: {
          'message': prompt.toString(),
          'domain': _domainKey(ctx.domain),
          'severity': ctx.severity,
        },
      );
      if (response is Map) {
        final reply = (response['reply'] ?? response['message'] ?? '').toString().trim();
        if (reply.isNotEmpty) {
          _turns.add({'user': text, 'assistant': reply});
          return reply;
        }
        final err = response['error']?.toString();
        if (err != null && err.isNotEmpty) {
          if (err.contains('not configured')) {
            _serverConfigured = false;
          }
          throw StateError(err);
        }
      }
      throw StateError('Empty AI response.');
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('not configured')) {
        throw StateError(
          'AI assistant is not configured on the server. '
          'Ask your admin to set GEMINI_API_KEY on Django (Render env / .env). '
          'The key must not be embedded in the mobile app.',
        );
      }
      throw StateError('AI chat failed: $e');
    }
  }
}
