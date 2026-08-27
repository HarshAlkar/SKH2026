import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';

typedef SignalingCallback = void Function(Map<String, dynamic> data);

class SignalingService {
  static final SignalingService _instance = SignalingService._internal();
  factory SignalingService() => _instance;
  SignalingService._internal();

  io.Socket? _socket;
  String? _connectedUserId;
  String? _activeConsultationId;

  SignalingCallback? _onIncomingCall;
  SignalingCallback? _onPeerJoined;
  SignalingCallback? _onOffer;
  SignalingCallback? _onAnswer;
  SignalingCallback? _onIceCandidate;
  SignalingCallback? _onHangup;
  SignalingCallback? _onRejected;
  SignalingCallback? _onNewMessage;
  SignalingCallback? _onFallbackToChat;
  final List<SignalingCallback> _chatListeners = [];
  void Function()? _onDisconnected;
  void Function()? _onReconnected;

  String get serverUrl => AppConfig.signalingServerUrl;
  bool get isConnected => _socket?.connected ?? false;
  String? get connectedUserId => _connectedUserId;

  void connect(String userId) {
    if (_connectedUserId == userId && (_socket?.connected ?? false)) {
      return;
    }

    disconnect();
    _connectedUserId = userId;

    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setQuery({'userId': userId})
          .enableForceNew()
          .enableReconnection()
          .setReconnectionAttempts(99)
          .setReconnectionDelay(1000)
          .build(),
    );

    _bindEvents();
    _socket!.connect();
  }

  void _bindEvents() {
    final socket = _socket;
    if (socket == null) return;

    socket.onConnect((_) {
      print('Signaling connected for user $_connectedUserId');
      if (_activeConsultationId != null) {
        joinRoom(_activeConsultationId!);
      }
      _onReconnected?.call();
    });
    socket.onDisconnect((_) {
      print('Signaling disconnected');
      _onDisconnected?.call();
    });
    socket.onConnectError((err) => print('Signaling Connect Error: $err'));
    socket.onError((err) => print('Signaling Error: $err'));

    socket.on('incoming-call', (data) {
      _onIncomingCall?.call(Map<String, dynamic>.from(data as Map));
    });
    socket.on('peer-joined', (data) {
      _onPeerJoined?.call(Map<String, dynamic>.from(data as Map));
    });
    socket.on('offer', (data) {
      _onOffer?.call(Map<String, dynamic>.from(data as Map));
    });
    socket.on('answer', (data) {
      _onAnswer?.call(Map<String, dynamic>.from(data as Map));
    });
    socket.on('ice-candidate', (data) {
      _onIceCandidate?.call(Map<String, dynamic>.from(data as Map));
    });
    socket.on('hangup', (data) {
      _onHangup?.call(Map<String, dynamic>.from(data as Map));
    });
    socket.on('call-rejected', (data) {
      _onRejected?.call(Map<String, dynamic>.from(data as Map));
    });
    socket.on('new-message', (data) {
      _onNewMessage?.call(Map<String, dynamic>.from(data as Map));
    });
    socket.on('fallback-to-chat', (data) {
      _onFallbackToChat?.call(Map<String, dynamic>.from(data as Map));
    });
    socket.on('chat-message', (data) {
      final payload = Map<String, dynamic>.from(data as Map);
      for (final listener in List<SignalingCallback>.from(_chatListeners)) {
        listener(payload);
      }
    });
  }

  void joinRoom(String roomId) {
    _activeConsultationId = roomId;
    print('Joining room: $roomId');
    _socket?.emit('join-consultation', roomId);
  }

  void leaveRoom(String roomId) {
    if (_activeConsultationId == roomId) {
      _activeConsultationId = null;
    }
    _socket?.emit('leave-consultation', roomId);
  }

  void sendCallRequest({
    required String receiverId,
    required String consultationId,
    required String callerName,
    required String callType,
    String? callerUserId,
  }) {
    _socket?.emit('call-request', {
      'receiverId': receiverId,
      'consultationId': consultationId,
      'callerName': callerName,
      'callType': callType,
      if (callerUserId != null) 'callerUserId': callerUserId,
    });
  }

  void emitHangup(String roomId) {
    _socket?.emit('hangup', {'consultationId': roomId});
  }

  void emitReject(String roomId, {String? receiverId}) {
    _socket?.emit('reject-call', {
      'consultationId': roomId,
      if (receiverId != null) 'receiverId': receiverId,
    });
  }

  void emitFallbackToChat(String roomId, String reason) {
    _socket?.emit('fallback-to-chat', {
      'consultationId': roomId,
      'reason': reason,
    });
  }

  void sendMessage({
    required String consultationId,
    required String text,
    required String senderId,
  }) {
    _socket?.emit('send-message', {
      'consultationId': consultationId,
      'text': text,
      'senderId': senderId,
    });
  }

  void sendPersistentChat({
    required String receiverId,
    required int threadId,
    required String text,
    required String senderId,
    String senderName = '',
    int? messageId,
  }) {
    _socket?.emit('chat-message', {
      'receiverId': receiverId,
      'threadId': threadId,
      'text': text,
      'senderId': senderId,
      'senderName': senderName,
      'messageId': messageId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void addChatListener(SignalingCallback callback) {
    if (!_chatListeners.contains(callback)) {
      _chatListeners.add(callback);
    }
  }

  void removeChatListener(SignalingCallback callback) {
    _chatListeners.remove(callback);
  }

  void onIncomingCall(SignalingCallback callback) => _onIncomingCall = callback;
  void onPeerJoined(SignalingCallback callback) => _onPeerJoined = callback;
  void onOffer(SignalingCallback callback) => _onOffer = callback;
  void onAnswer(SignalingCallback callback) => _onAnswer = callback;
  void onIceCandidate(SignalingCallback callback) => _onIceCandidate = callback;
  void onHangup(SignalingCallback callback) => _onHangup = callback;
  void onRejected(SignalingCallback callback) => _onRejected = callback;
  void onNewMessage(SignalingCallback callback) => _onNewMessage = callback;
  void onFallbackToChat(SignalingCallback callback) => _onFallbackToChat = callback;
  void onDisconnected(void Function() callback) => _onDisconnected = callback;
  void onReconnected(void Function() callback) => _onReconnected = callback;

  void emitOffer(String roomId, Map<String, dynamic> offer) {
    print('Emitting offer for room: $roomId');
    _socket?.emit('offer', {'consultationId': roomId, 'offer': offer});
  }

  void emitAnswer(String roomId, Map<String, dynamic> answer) {
    print('Emitting answer for room: $roomId');
    _socket?.emit('answer', {'consultationId': roomId, 'answer': answer});
  }

  void emitIceCandidate(String roomId, Map<String, dynamic> candidate) {
    _socket?.emit('ice-candidate', {'consultationId': roomId, 'candidate': candidate});
  }

  /// Drop in-call listeners so a disposed CallScreen cannot pop routes later.
  void clearCallListeners() {
    _onPeerJoined = null;
    _onOffer = null;
    _onAnswer = null;
    _onIceCandidate = null;
    _onHangup = null;
    _onRejected = null;
    _onNewMessage = null;
    _onFallbackToChat = null;
    _onDisconnected = null;
    _onReconnected = null;
  }

  void disconnect() {
    _activeConsultationId = null;
    _socket?.dispose();
    _socket = null;
    _connectedUserId = null;
  }

  void dispose() => disconnect();

  io.Socket? get socket => _socket;
}
