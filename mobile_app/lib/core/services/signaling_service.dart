import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';

class SignalingService {
  static final SignalingService _instance = SignalingService._internal();
  factory SignalingService() => _instance;
  SignalingService._internal();

  io.Socket? _socket;
  final String serverUrl = AppConfig.signalingServerUrl;

  void connect(String userId) {
    if (_socket?.connected ?? false) return;

    _socket = io.io(serverUrl, io.OptionBuilder()
      .setTransports(['websocket'])
      .setQuery({'userId': userId})
      .build());

    _socket!.onConnect((_) {
      print('Signaling connected for user $userId');
    });

    _socket!.onDisconnect((_) => print('Signaling disconnected'));
    
    _socket!.onConnectError((err) => print('Signaling Connect Error: $err'));
    _socket!.onError((err) => print('Signaling Error: $err'));
  }

  void joinRoom(String roomId) {
    print('Joining room: $roomId');
    _socket?.emit('join-consultation', roomId);
  }

  void sendCallRequest({
    required String receiverId,
    required String consultationId,
    required String callerName,
    required String callType,
  }) {
    _socket?.emit('call-request', {
      'receiverId': receiverId,
      'consultationId': consultationId,
      'callerName': callerName,
      'callType': callType,
    });
  }

  void onIncomingCall(Function(Map<String, dynamic>) callback) {
    _socket?.on('incoming-call', (data) => callback(Map<String, dynamic>.from(data)));
  }

  void onPeerJoined(Function(Map<String, dynamic>) callback) {
    _socket?.on('peer-joined', (data) => callback(Map<String, dynamic>.from(data)));
  }

  void onOffer(Function(Map<String, dynamic>) callback) {
    _socket?.on('offer', (data) => callback(Map<String, dynamic>.from(data)));
  }

  void onAnswer(Function(Map<String, dynamic>) callback) {
    _socket?.on('answer', (data) => callback(Map<String, dynamic>.from(data)));
  }

  void onIceCandidate(Function(Map<String, dynamic>) callback) {
    _socket?.on('ice-candidate', (data) => callback(Map<String, dynamic>.from(data)));
  }

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

  void dispose() {
    _socket?.dispose();
    _socket = null;
  }

  io.Socket? get socket => _socket;
}
