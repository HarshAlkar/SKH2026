import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/signaling_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../services/chat_service.dart';
import '../services/chat_local_store.dart';
import '../widgets/chat_image_picker.dart';

class ChatScreen extends StatefulWidget {
  final int peerUserId;
  final String peerName;
  final String? peerPhone;

  const ChatScreen({
    super.key,
    required this.peerUserId,
    required this.peerName,
    this.peerPhone,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chat = ChatService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  String? _error;
  int? _threadId;
  late final SignalingCallback _onChat;

  @override
  void initState() {
    super.initState();
    _onChat = (data) {
      final senderId = data['senderId']?.toString();
      final me = context.read<AuthProvider>().user?.id.toString();
      if (senderId == me) return;
      final threadId = int.tryParse(data['threadId']?.toString() ?? '');
      if (_threadId != null && threadId != null && threadId != _threadId) return;
      setState(() {
        _messages.add({
          'id': data['messageId'],
          'sender_id': int.tryParse(senderId ?? ''),
          'text': data['text'] ?? '',
          'image_url': data['imageUrl'] ?? data['image_url'],
          'created_at': data['timestamp'],
        });
      });
      if (_threadId != null) {
        ChatService().persistIncoming(
          threadId: _threadId!,
          peerUserId: widget.peerUserId,
          peerName: widget.peerName,
          text: data['text']?.toString() ?? '',
          messageId: int.tryParse(data['messageId']?.toString() ?? ''),
          senderId: int.tryParse(senderId ?? ''),
          createdAt: data['timestamp']?.toString(),
          imageUrl: data['imageUrl']?.toString() ?? data['image_url']?.toString(),
        );
      }
      _jumpToEnd();
    };
    SignalingService().addChatListener(_onChat);
    ChatSession.openPeerUserId = widget.peerUserId;
    _openThread();
  }

  @override
  void dispose() {
    if (ChatSession.openThreadId == _threadId) {
      ChatSession.openThreadId = null;
    }
    if (ChatSession.openPeerUserId == widget.peerUserId) {
      ChatSession.openPeerUserId = null;
    }
    SignalingService().removeChatListener(_onChat);
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _openThread() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final thread = await _chat.openThread(widget.peerUserId);
      final threadId = int.tryParse(thread['id'].toString());
      if (threadId == null) {
        throw Exception('Could not open chat');
      }
      ChatSession.openThreadId = threadId;
      final localMessages = await ChatLocalStore.instance.listMessages(threadId);
      if (mounted && localMessages.isNotEmpty) {
        setState(() {
          _threadId = threadId;
          _messages
            ..clear()
            ..addAll(localMessages);
          _loading = false;
        });
        _jumpToEnd();
      }
      final messages = await _chat.getMessages(threadId);
      if (!mounted) return;
      setState(() {
        _threadId = threadId;
        _messages
          ..clear()
          ..addAll(messages);
        _loading = false;
      });
      _jumpToEnd();
    } catch (e) {
      final local = await ChatLocalStore.instance.getThreadByPeer(widget.peerUserId);
      if (local != null && mounted) {
        final threadId = int.tryParse(local['id'].toString());
        if (threadId != null) {
          ChatSession.openThreadId = threadId;
          final messages = await ChatLocalStore.instance.listMessages(threadId);
          setState(() {
            _threadId = threadId;
            _messages
              ..clear()
              ..addAll(messages);
            _loading = false;
            _error = null;
          });
          _jumpToEnd();
          return;
        }
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load chat. Try again.';
      });
    }
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send({File? image}) async {
    final text = _controller.text.trim();
    if ((text.isEmpty && image == null) || _threadId == null) return;
    _controller.clear();
    try {
      final auth = context.read<AuthProvider>();
      final saved = await _chat.sendMessage(
        _threadId!,
        text,
        senderId: auth.user?.id,
        image: image,
      );
      if (!mounted) return;
      setState(() => _messages.add(saved));
      _jumpToEnd();
      if (saved['pending_sync'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved on this phone. Will send when internet is back.'),
          ),
        );
      } else {
        SignalingService().sendPersistentChat(
          receiverId: widget.peerUserId.toString(),
          threadId: _threadId!,
          text: saved['text']?.toString() ?? text,
          imageUrl: saved['image_url']?.toString(),
          senderId: auth.user?.id.toString() ?? '',
          senderName: auth.user?.name ?? '',
          messageId: int.tryParse(saved['id']?.toString() ?? ''),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message failed to send')),
      );
    }
  }

  Future<void> _sendPhoto() async {
    final file = await ChatImagePicker.pick(context);
    if (file == null || !mounted) return;
    await _send(image: file);
  }

  Future<void> _dial() async {
    final phone = widget.peerPhone?.trim() ?? '';
    if (phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  bool _isMine(Map<String, dynamic> message) {
    final me = context.read<AuthProvider>().user?.id;
    final sender = message['sender_id'];
    if (sender is int) return sender == me;
    return int.tryParse(sender?.toString() ?? '') == me;
  }

  Widget _imageFor(String url, {required bool mine}) {
    ImageProvider provider;
    if (url.startsWith('http')) {
      provider = NetworkImage(url);
    } else {
      provider = FileImage(File(url));
    }
    return GestureDetector(
      onTap: () => _openPhoto(url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image(
          image: provider,
          width: 220,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.broken_image_outlined,
            color: mine ? Colors.white70 : Colors.grey,
          ),
        ),
      ),
    );
  }

  void _openPhoto(String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: url.startsWith('http')
              ? Image.network(url, fit: BoxFit.contain)
              : Image.file(File(url), fit: BoxFit.contain),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.peerName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if ((widget.peerPhone ?? '').isNotEmpty)
              Text(
                widget.peerPhone!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          if ((widget.peerPhone ?? '').isNotEmpty)
            IconButton(
              tooltip: 'Call phone',
              onPressed: _dial,
              icon: const Icon(Icons.call, color: AppColors.primary),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _openThread,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _messages.isEmpty
                        ? const Center(child: Text('No messages yet. Say hello.'))
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final mine = _isMine(message);
                              return Align(
                                alignment: mine
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: mine ? AppColors.primary : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if ((message['image_url']?.toString() ?? '').isNotEmpty)
                                        _imageFor(
                                          message['image_url'].toString(),
                                          mine: mine,
                                        ),
                                      if ((message['text']?.toString() ?? '').isNotEmpty &&
                                          message['text'].toString() != '[Photo]') ...[
                                        if ((message['image_url']?.toString() ?? '').isNotEmpty)
                                          const SizedBox(height: 8),
                                        Text(
                                          message['text']?.toString() ?? '',
                                          style: TextStyle(
                                            color: mine ? Colors.white : AppColors.textPrimary,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                      if (message['pending_sync'] == true) ...[
                                        const SizedBox(height: 4),
                                        Icon(
                                          Icons.schedule,
                                          size: 14,
                                          color: mine ? Colors.white70 : Colors.grey,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
          SafeArea(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Send photo',
                    onPressed: _threadId == null ? null : _sendPhoto,
                    icon: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      onPressed: _send,
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
