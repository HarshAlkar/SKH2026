import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../one_health/escalation_policy.dart';
import '../../one_health/screening_disclaimer.dart';
import '../models/screening_chat_context.dart';
import '../services/gemini_health_chat_service.dart';

/// Reusable AI health chat for human / skin / livestock / child screening.
class SharedAIHealthChat extends StatefulWidget {
  final ScreeningChatContext screeningContext;

  const SharedAIHealthChat({
    super.key,
    required this.screeningContext,
  });

  static Future<void> open(
    BuildContext context, {
    required ScreeningChatContext screeningContext,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SharedAIHealthChat(screeningContext: screeningContext),
      ),
    );
  }

  @override
  State<SharedAIHealthChat> createState() => _SharedAIHealthChatState();
}

class _SharedAIHealthChatState extends State<SharedAIHealthChat> {
  final _service = GeminiHealthChatService.instance;
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<_ChatBubble> _messages = [];
  bool _booting = true;
  bool _sending = false;
  String? _offlineNote;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _service.reset();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final online = await _service.isOnline;
    if (!mounted) return;
    if (!online) {
      setState(() {
        _booting = false;
        _offlineNote =
            'AI chat requires an internet connection, but your screening result '
            'and recommended next steps are available offline.';
      });
      return;
    }
    if (!_service.isConfigured) {
      setState(() {
        _booting = false;
        _offlineNote =
            'AI chat is not configured on this build. Screening results remain available offline.';
      });
      return;
    }
    try {
      await _service.startSession(widget.screeningContext);
      if (!mounted) return;
      setState(() {
        _booting = false;
        _messages.add(
          _ChatBubble(
            fromUser: false,
            text:
                'I can help explain this ${widget.screeningContext.domainLabel} result in simple language. '
                'Ask what it means, what to watch for, or what to do next.\n\n'
                '${_disclaimerLine()}',
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _booting = false;
        _offlineNote = e.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  String _disclaimerLine() {
    final animal = widget.screeningContext.domain == ScreeningDomain.livestock;
    return ScreeningDisclaimer.text(language: 'en', isAnimal: animal);
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _messages.add(_ChatBubble(fromUser: true, text: text));
      _controller.clear();
    });
    _scrollToEnd();
    try {
      final reply = await _service.sendMessage(text);
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatBubble(fromUser: false, text: reply));
        _sending = false;
      });
      _scrollToEnd();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _messages.add(
          _ChatBubble(
            fromUser: false,
            text: e.toString().replaceFirst('Bad state: ', ''),
            isError: true,
          ),
        );
      });
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctx = widget.screeningContext;
    final band = EscalationPolicy.normalize(ctx.severity);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Ask AI about this', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Possible finding: ${ctx.possibleFinding}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Risk: $band · ${ctx.domainLabel}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 6),
                Text(
                  _disclaimerLine(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF94A3B8),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_booting)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_offlineNote != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey.shade500),
                    const SizedBox(height: 16),
                    Text(
                      _offlineNote!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700, height: 1.45),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back to screening result'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_sending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_sending && index == _messages.length) {
                    return const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Thinking…', style: TextStyle(color: Color(0xFF94A3B8))),
                      ),
                    );
                  }
                  final m = _messages[index];
                  return Align(
                    alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.82,
                      ),
                      decoration: BoxDecoration(
                        color: m.isError
                            ? const Color(0xFFFFF1F2)
                            : (m.fromUser ? AppColors.primary : Colors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: m.fromUser
                            ? null
                            : Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        m.text,
                        style: TextStyle(
                          color: m.isError
                              ? const Color(0xFF9F1239)
                              : (m.fromUser ? Colors.white : const Color(0xFF1E293B)),
                          height: 1.4,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          hintText: 'Ask a question…',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _sending ? null : _send,
                      style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChatBubble {
  final bool fromUser;
  final String text;
  final bool isError;

  _ChatBubble({
    required this.fromUser,
    required this.text,
    this.isError = false,
  });
}
