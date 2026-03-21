import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';

class SignalingService {
  IO.Socket? _socket;
  
  // Callbacks
  Function(Map<String, dynamic>)? _onOffer;
  Function(Map<String, dynamic>)? _onAnswer;
  Function(Map<String, dynamic>)? _onIceCandidate;
  Function(Map<String, dynamic>)? _onIncomingCall;
  Function(Map<String, dynamic>)? _onPeerJoined;

  void connect(String userId) {
    _socket = IO.io(ApiConstants.voiceSignalingUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .setQuery({'userId': userId})
      .build());

    _socket!.onConnect((_) {
      print('Signaling Socket Connected: userId=$userId');
    });

    _socket!.on('offer', (data) {
      if (_onOffer != null) _onOffer!(Map<String, dynamic>.from(data));
    });

    _socket!.on('answer', (data) {
      if (_onAnswer != null) _onAnswer!(Map<String, dynamic>.from(data));
    });

    _socket!.on('ice-candidate', (data) {
      if (_onIceCandidate != null) _onIceCandidate!(Map<String, dynamic>.from(data));
    });

    _socket!.on('incoming-call', (data) {
      if (_onIncomingCall != null) _onIncomingCall!(Map<String, dynamic>.from(data));
    });

    _socket!.on('peer-joined', (data) {
      if (_onPeerJoined != null) _onPeerJoined!(Map<String, dynamic>.from(data));
    });
  }

  // Socket Actions
  void joinRoom(String roomId) {
    _socket?.emit('join-consultation', roomId);
  }

  void leaveRoom(String roomId) {
     _socket?.emit('leave-consultation', roomId);
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

  void emitOffer(String roomId, Map<String, dynamic> offer) {
    _socket?.emit('offer', {'consultationId': roomId, 'offer': offer});
  }

  void emitAnswer(String roomId, Map<String, dynamic> answer) {
    _socket?.emit('answer', {'consultationId': roomId, 'answer': answer});
  }

  void emitIceCandidate(String roomId, Map<String, dynamic> candidate) {
    _socket?.emit('ice-candidate', {'consultationId': roomId, 'candidate': candidate});
  }

  // Setters for callbacks
  void onOffer(Function(Map<String, dynamic>) callback) => _onOffer = callback;
  void onAnswer(Function(Map<String, dynamic>) callback) => _onAnswer = callback;
  void onIceCandidate(Function(Map<String, dynamic>) callback) => _onIceCandidate = callback;
  void onIncomingCall(Function(Map<String, dynamic>) callback) => _onIncomingCall = callback;
  void onPeerJoined(Function(Map<String, dynamic>) callback) => _onPeerJoined = callback;

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
  }
}
