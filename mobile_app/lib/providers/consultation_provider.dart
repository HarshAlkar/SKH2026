import 'package:flutter/material.dart';
import '../features/user/services/doctor_service.dart';
import '../core/services/signaling_service.dart';
import '../core/services/notification_service.dart';
import '../features/chat/services/chat_service.dart';
import '../features/chat/services/chat_local_store.dart';
import '../features/user/screens/incoming_call_screen.dart';
import '../main.dart';

class ConsultationProvider extends ChangeNotifier {
  final DoctorService _doctorService = DoctorService();
  final SignalingService _signaling = SignalingService();
  final ChatService _chat = ChatService();

  List<Map<String, dynamic>> _history = [];
  bool _isLoading = false;
  bool _chatListenerAttached = false;
  String? _incomingConsultationId;

  List<Map<String, dynamic>> get history => _history;
  bool get isLoading => _isLoading;

  void initSignaling(String userId) {
    _signaling.connect(userId);

    _signaling.onIncomingCall((data) {
      _handleIncomingCall(data);
    });

    if (!_chatListenerAttached) {
      _chatListenerAttached = true;
      _signaling.addChatListener(_onGlobalChat);
    }
  }

  void _onGlobalChat(Map<String, dynamic> data) {
    final threadId = int.tryParse(data['threadId']?.toString() ?? '');
    final senderId = int.tryParse(data['senderId']?.toString() ?? '');
    final text = data['text']?.toString() ?? '';
    if (threadId == null || text.isEmpty) return;
    if (data['senderId']?.toString() == _signaling.connectedUserId) return;

    final peerUserId = senderId ?? 0;
    final peerName = data['senderName']?.toString() ?? 'New message';
    _chat.persistIncoming(
      threadId: threadId,
      peerUserId: peerUserId,
      peerName: peerName,
      text: text,
      messageId: int.tryParse(data['messageId']?.toString() ?? ''),
      senderId: senderId,
      createdAt: data['timestamp']?.toString(),
    );

    final viewingThisThread = ChatSession.openThreadId == threadId ||
        ChatSession.openPeerUserId == peerUserId;
    if (viewingThisThread) return;

    NotificationService().showChatMessage(
      threadId: threadId,
      peerUserId: peerUserId,
      peerName: peerName,
      text: text,
    );
  }

  void _handleIncomingCall(Map<String, dynamic> data) {
    final consultationId = data['consultationId'].toString();
    final callerName = data['callerName'] ?? 'Doctor';
    final callType = data['callType'] ?? 'VIDEO';
    final callerUserId = int.tryParse(data['callerUserId']?.toString() ?? '');

    if (_incomingConsultationId == consultationId) return;
    _incomingConsultationId = consultationId;

    NotificationService().showIncomingCall(
      consultationId: consultationId,
      callerName: callerName.toString(),
      callType: callType.toString(),
      callerUserId: callerUserId,
    );

    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IncomingCallScreen(
            consultationId: consultationId,
            callerName: callerName.toString(),
            callType: callType.toString(),
            callerUserId: callerUserId,
          ),
        ),
      ).whenComplete(() {
        if (_incomingConsultationId == consultationId) {
          _incomingConsultationId = null;
        }
        NotificationService().cancelIncomingCall(consultationId);
      });
    }
  }

  Future<void> fetchHistory() async {
    _isLoading = true;
    notifyListeners();
    try {
      _history = await _doctorService.getConsultationHistory();
    } catch (e) {
      print('Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _signaling.dispose();
    super.dispose();
  }
}
