import '../../../core/services/api_service.dart';
import '../../../core/sync/offline_api.dart';
import 'chat_local_store.dart';

class ChatService {
  final ApiService _api = ApiService();
  final ChatLocalStore _local = ChatLocalStore.instance;
  final OfflineApi _offline = OfflineApi.instance;

  bool _isNetworkFailure(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('socket') ||
        message.contains('timeout') ||
        message.contains('connection') ||
        message.contains('network') ||
        message.contains('failed host lookup');
  }

  Future<Map<String, dynamic>> openThread(int peerUserId) async {
    final response = await _api.post(
      '/chat/threads/open/',
      body: {'peer_user_id': peerUserId},
    );
    final thread = Map<String, dynamic>.from(response as Map);
    await _local.upsertThread(thread, hidden: false);
    return thread;
  }

  Future<List<Map<String, dynamic>>> listThreads({bool hidden = false}) async {
    final cached = await _local.listThreads(hidden: hidden);
    if (hidden) return cached;
    try {
      final response = await _api.get('/chat/threads/');
      if (response is List) {
        final remote = List<Map<String, dynamic>>.from(response);
        await _local.mergeRemoteThreads(remote);
      }
      return await _local.listThreads(hidden: false);
    } catch (_) {
      return cached;
    }
  }

  Future<List<Map<String, dynamic>>> getMessages(int threadId) async {
    final cached = await _local.listMessages(threadId);
    try {
      final response = await _api.get('/chat/threads/$threadId/messages/');
      if (response is List) {
        final remote = List<Map<String, dynamic>>.from(response);
        await _local.replaceMessages(threadId, remote);
        return await _local.listMessages(threadId);
      }
    } catch (_) {}
    return cached;
  }

  Future<Map<String, dynamic>> sendMessage(
    int threadId,
    String text, {
    int? senderId,
  }) async {
    try {
      final response = await _api.post(
        '/chat/threads/$threadId/messages/',
        body: {'text': text},
      );
      final saved = Map<String, dynamic>.from(response as Map);
      await _local.upsertMessage(
        serverId: int.tryParse(saved['id']?.toString() ?? ''),
        threadId: threadId,
        senderId: int.tryParse(saved['sender_id']?.toString() ?? '') ?? senderId,
        text: saved['text']?.toString() ?? text,
        createdAt: saved['created_at']?.toString(),
      );
      return saved;
    } catch (e) {
      if (!_isNetworkFailure(e)) rethrow;
    }

    final clientId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().toIso8601String();
    await _local.upsertPendingMessage(
      clientId: clientId,
      threadId: threadId,
      senderId: senderId,
      text: text,
      createdAt: now,
    );
    await _offline.post(
      '/chat/threads/$threadId/messages/',
      body: {
        'text': text,
        'client_message_id': clientId,
        'thread_id': threadId,
      },
    );
    return {
      'id': clientId,
      'thread': threadId,
      'sender_id': senderId,
      'text': text,
      'created_at': now,
      'pending_sync': true,
    };
  }

  Future<void> hideThread(int threadId) async {
    await _local.setHidden(threadId, true);
    try {
      await _api.post('/chat/threads/$threadId/hide/');
    } catch (_) {}
  }

  Future<void> unhideThread(int threadId) async {
    await _local.setHidden(threadId, false);
    try {
      await _api.post('/chat/threads/$threadId/unhide/');
    } catch (_) {}
  }

  Future<void> persistIncoming({
    required int threadId,
    required int peerUserId,
    required String peerName,
    required String text,
    int? messageId,
    int? senderId,
    String? createdAt,
  }) async {
    await _local.upsertThread({
      'id': threadId,
      'peer_user_id': peerUserId,
      'peer_name': peerName,
      'last_message': {'text': text, 'created_at': createdAt},
    });
    await _local.upsertMessage(
      serverId: messageId,
      threadId: threadId,
      senderId: senderId,
      text: text,
      createdAt: createdAt,
      peerName: peerName,
      peerUserId: peerUserId,
    );
  }
}
