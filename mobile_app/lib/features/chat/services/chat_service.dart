import '../../../core/services/api_service.dart';

class ChatService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> openThread(int peerUserId) async {
    final response = await _api.post(
      '/chat/threads/open/',
      body: {'peer_user_id': peerUserId},
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<List<Map<String, dynamic>>> listThreads() async {
    final response = await _api.get('/chat/threads/');
    if (response is List) {
      return List<Map<String, dynamic>>.from(response);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getMessages(int threadId) async {
    final response = await _api.get('/chat/threads/$threadId/messages/');
    if (response is List) {
      return List<Map<String, dynamic>>.from(response);
    }
    return [];
  }

  Future<Map<String, dynamic>> sendMessage(int threadId, String text) async {
    final response = await _api.post(
      '/chat/threads/$threadId/messages/',
      body: {'text': text},
    );
    return Map<String, dynamic>.from(response as Map);
  }
}
