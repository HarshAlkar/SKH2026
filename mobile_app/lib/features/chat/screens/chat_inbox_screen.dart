import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  final ChatService _chat = ChatService();
  List<Map<String, dynamic>> _threads = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final threads = await _chat.listThreads();
      if (!mounted) return;
      setState(() {
        _threads = threads;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Messages',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _threads.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('No conversations yet')),
                      ],
                    )
                  : ListView.builder(
                      itemCount: _threads.length,
                      itemBuilder: (context, index) {
                        final thread = _threads[index];
                        final last = thread['last_message'] is Map
                            ? Map<String, dynamic>.from(thread['last_message'] as Map)
                            : null;
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.lightBlue,
                            child: Icon(Icons.person, color: AppColors.primary),
                          ),
                          title: Text(
                            thread['peer_name']?.toString() ?? 'Chat',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            last?['text']?.toString() ?? 'No messages',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: (thread['unread_count'] ?? 0) > 0
                              ? CircleAvatar(
                                  radius: 12,
                                  backgroundColor: AppColors.primary,
                                  child: Text(
                                    '${thread['unread_count']}',
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
                                  ),
                                )
                              : null,
                          onTap: () async {
                            final peerId = int.tryParse(thread['peer_user_id'].toString());
                            if (peerId == null) return;
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  peerUserId: peerId,
                                  peerName: thread['peer_name']?.toString() ?? 'Chat',
                                  peerPhone: thread['peer_phone']?.toString(),
                                ),
                              ),
                            );
                            _load();
                          },
                        );
                      },
                    ),
            ),
    );
  }
}
