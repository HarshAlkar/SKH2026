import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import '../widgets/chat_image_picker.dart';

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen>
    with SingleTickerProviderStateMixin {
  final ChatService _chat = ChatService();
  late TabController _tabs;
  List<Map<String, dynamic>> _threads = [];
  List<Map<String, dynamic>> _deleted = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final visible = await _chat.listThreads(hidden: false);
    final hidden = await _chat.listThreads(hidden: true);
    if (!mounted) return;
    setState(() {
      _threads = visible;
      _deleted = hidden;
      _loading = false;
    });
  }

  Future<void> _openThread(Map<String, dynamic> thread, {bool restore = false}) async {
    final peerId = int.tryParse(thread['peer_user_id'].toString());
    if (peerId == null) return;
    final threadId = int.tryParse(thread['id']?.toString() ?? '');
    if (restore && threadId != null) {
      await _chat.unhideThread(threadId);
    }
    if (!mounted) return;
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
  }

  Future<void> _hideThread(Map<String, dynamic> thread) async {
    final threadId = int.tryParse(thread['id']?.toString() ?? '');
    if (threadId == null) return;
    await _chat.hideThread(threadId);
    _load();
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
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: 'Chats (${_threads.length})'),
            Tab(text: 'Deleted (${_deleted.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _buildList(_threads, empty: 'No conversations yet', allowDelete: true),
                _buildList(
                  _deleted,
                  empty: 'No deleted chats. Deleted conversations stay saved on this device.',
                  allowDelete: false,
                ),
              ],
            ),
    );
  }

  Widget _buildList(
    List<Map<String, dynamic>> items, {
    required String empty,
    required bool allowDelete,
  }) {
    return RefreshIndicator(
      onRefresh: _load,
      child: items.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 120),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(empty, textAlign: TextAlign.center),
                ),
              ],
            )
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final thread = items[index];
                final last = thread['last_message'] is Map
                    ? Map<String, dynamic>.from(thread['last_message'] as Map)
                    : null;
                final tile = ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.lightBlue,
                    child: Icon(Icons.person, color: AppColors.primary),
                  ),
                  title: Text(
                    thread['peer_name']?.toString() ?? 'Chat',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    chatPreviewText(last),
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
                      : (allowDelete
                          ? IconButton(
                              tooltip: 'Delete conversation',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _hideThread(thread),
                            )
                          : TextButton(
                              onPressed: () => _openThread(thread, restore: true),
                              child: const Text('Restore'),
                            )),
                  onTap: () => _openThread(thread, restore: !allowDelete),
                  onLongPress: allowDelete ? () => _confirmDelete(thread) : null,
                );
                if (!allowDelete) return tile;
                return Dismissible(
                  key: ValueKey('thread-${thread['id']}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    await _confirmDelete(thread);
                    return false;
                  },
                  child: tile,
                );
              },
            ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> thread) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete conversation'),
        content: const Text(
          'This hides the chat from your inbox. Messages stay saved on this device and in Deleted chats.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await _hideThread(thread);
    }
  }
}
