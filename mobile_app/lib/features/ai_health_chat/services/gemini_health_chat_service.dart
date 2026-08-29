import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/connectivity_service.dart';
import '../../one_health/escalation_policy.dart';
import '../models/screening_chat_context.dart';

class GeminiHealthChatService {
  GeminiHealthChatService._();
  static final GeminiHealthChatService instance = GeminiHealthChatService._();

  GenerativeModel? _model;
  ChatSession? _session;
  ScreeningChatContext? _context;
  final List<Content> _history = [];
  bool _useRest = false;

  static const _models = [
    'gemini-3.6-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
    'gemini-1.5-flash-latest',
  ];

  bool get isConfigured => AppConfig.hasGeminiKey;

  Future<bool> get isOnline async => ConnectivityService().isConnected();

  void reset() {
    _session = null;
    _context = null;
    _model = null;
    _history.clear();
    _useRest = false;
  }

  String _systemPrompt(ScreeningChatContext ctx) {
    final role = switch (ctx.domain) {
      ScreeningDomain.human =>
        'You are a health decision-support assistant inside VitalReach.',
      ScreeningDomain.skin =>
        'You are a skin-screening explanation assistant inside VitalReach.',
      ScreeningDomain.livestock =>
        'You are a veterinary health decision-support assistant inside VitalReach.',
      ScreeningDomain.child =>
        'You are a child-development screening support assistant inside VitalReach.',
    };

    final domainRules = switch (ctx.domain) {
      ScreeningDomain.livestock =>
        'You do NOT provide a final veterinary diagnosis. '
            'Explain screening results, ask clarifying questions, provide general safe next steps, '
            'and recommend veterinary evaluation when risk is High or Critical. '
            'Always state: "This AI guidance is not a veterinary diagnosis."',
      ScreeningDomain.child =>
        'You do NOT diagnose developmental conditions. '
            'Use parent-friendly language. Never say "your child has condition X". '
            'Prefer: further professional assessment may be helpful. '
            'Always state: "This AI guidance is not a medical diagnosis."',
      _ =>
        'You do NOT provide a final medical diagnosis. '
            'Explain screening results, ask clarifying questions, provide general safe next steps, '
            'and recommend qualified healthcare evaluation when risk is High or Critical. '
            'Always state: "This AI guidance is not a medical diagnosis."',
    };

    return '''
$role
$domainRules

Safety rules (mandatory):
- AI-assisted screening only. Never claim certainty.
- Do not prescribe drugs, dosages, injections, or dangerous treatments.
- Do not invent lab results or clinical findings not in the screening context.
- Keep answers short, plain language, and practical for rural / field users.
- If risk is High or Critical, clearly explain why professional evaluation is recommended.
- If the user asks whether they can wait, use the risk level to advise safely.

Current screening context:
${ctx.toPromptBlock()}
''';
  }

  Future<void> startSession(ScreeningChatContext context) async {
    if (!isConfigured) {
      throw StateError('Gemini API key is not configured.');
    }
    _context = context;
    _history.clear();
    // Prefer REST first for broader API-key compatibility; SDK as secondary.
    _useRest = true;
    _session = null;
    _model = null;
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
    if (!isConfigured) {
      throw StateError('Gemini API key is not configured.');
    }
    final ctx = _context;
    if (ctx == null) {
      throw StateError('Chat session was not started.');
    }

    if (_useRest) {
      try {
        return await _sendViaRest(ctx, text);
      } catch (_) {
        _useRest = false;
      }
    }

    return _sendViaSdk(ctx, text);
  }

  Future<String> _sendViaSdk(ScreeningChatContext ctx, String text) async {
    var session = _session;
    if (session == null) {
      Object? lastError;
      for (final modelName in _models) {
        try {
          _model = GenerativeModel(
            model: modelName,
            apiKey: AppConfig.geminiApiKey,
            systemInstruction: Content.system(_systemPrompt(ctx)),
            generationConfig: GenerationConfig(
              temperature: 0.4,
              maxOutputTokens: 700,
            ),
          );
          _session = _model!.startChat();
          session = _session;
          break;
        } catch (e) {
          lastError = e;
        }
      }
      if (session == null) {
        throw StateError('AI chat failed to start: $lastError');
      }
    }
    final response = await session.sendMessage(Content.text(text));
    final out = response.text?.trim();
    if (out == null || out.isEmpty) {
      return 'I could not generate a response right now. Please try again, '
          'or contact a qualified professional if your risk is High or Critical.';
    }
    return out;
  }

  Future<String> _sendViaRest(ScreeningChatContext ctx, String text) async {
    _history.add(Content.text(text));
    Object? lastError;
    for (final modelName in _models) {
      try {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/'
          '$modelName:generateContent?key=${Uri.encodeQueryComponent(AppConfig.geminiApiKey)}',
        );
        final contents = <Map<String, dynamic>>[];
        for (final item in _history) {
          final role = item.role == 'model' ? 'model' : 'user';
          final parts = item.parts
              .whereType<TextPart>()
              .map((p) => {'text': p.text})
              .toList();
          if (parts.isEmpty) continue;
          contents.add({'role': role, 'parts': parts});
        }
        final body = {
          'system_instruction': {
            'parts': [
              {'text': _systemPrompt(ctx)},
            ],
          },
          'contents': contents,
          'generationConfig': {
            'temperature': 0.4,
            'maxOutputTokens': 700,
          },
        };
        final res = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 45));
        if (res.statusCode >= 400) {
          lastError = 'HTTP ${res.statusCode}: ${res.body}';
          continue;
        }
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        final candidates = decoded['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          lastError = 'Empty candidates';
          continue;
        }
        final content = (candidates.first as Map)['content'] as Map?;
        final parts = content?['parts'] as List?;
        final reply = parts
                ?.map((p) => (p as Map)['text']?.toString() ?? '')
                .where((t) => t.isNotEmpty)
                .join('\n')
                .trim() ??
            '';
        if (reply.isEmpty) {
          lastError = 'Empty reply';
          continue;
        }
        _history.add(Content.model([TextPart(reply)]));
        return reply;
      } catch (e) {
        lastError = e;
      }
    }
    if (_history.isNotEmpty) _history.removeLast();
    throw StateError('AI chat failed: $lastError');
  }
}
