import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  Future<void> initRenderers(RTCVideoRenderer local, RTCVideoRenderer remote) async {
    await local.initialize();
    await remote.initialize();
  }

  Future<void> openUserMedia(RTCVideoRenderer localVideo) async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {'facingMode': 'user'}
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    localVideo.srcObject = _localStream;
  }

  Future<void> createOffer() async {
    // Logic to create offer for WebRTC
  }

  void hangUp() {
    _localStream?.getTracks().forEach((track) => track.stop());
    _peerConnection?.close();
  }
}
