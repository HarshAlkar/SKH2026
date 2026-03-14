import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'signaling_service.dart';

class WebRTCService {
  final SignalingService _signaling = SignalingService();
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  final _remoteStreamController = StreamController<MediaStream?>.broadcast();
  Stream<MediaStream?> get onRemoteStream => _remoteStreamController.stream;

  final _connectionStateController = StreamController<RTCPeerConnectionState>.broadcast();
  Stream<RTCPeerConnectionState> get onConnectionState => _connectionStateController.stream;

  Future<void> init(String consultationId, {bool isOfferer = true}) async {
    _signaling.joinRoom(consultationId);
    
    _signaling.onOffer((data) async {
      if (!isOfferer) {
        await _setupPeerConnection(consultationId);
        await _handleOffer(data['offer'], consultationId);
      }
    });

    _signaling.onAnswer((data) async {
      if (isOfferer) {
        await _handleAnswer(data['answer']);
      }
    });

    _signaling.onIceCandidate((data) async {
      await _handleIceCandidate(data['candidate']);
    });
  }

  Future<void> _setupPeerConnection(String consultationId) async {
    if (_peerConnection != null) return;

    final Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection!.onIceCandidate = (candidate) {
      _signaling.emitIceCandidate(consultationId, candidate.toMap());
    };

    _peerConnection!.onAddStream = (stream) {
      _remoteStream = stream;
      _remoteStreamController.add(stream);
    };

    _peerConnection!.onConnectionState = (state) {
      _connectionStateController.add(state);
    };

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });
    
    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });
  }

  Future<void> startCall(String consultationId, {bool video = true}) async {
    await _setupPeerConnection(consultationId);

    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    _signaling.emitOffer(consultationId, offer.toMap());
  }

  Future<void> _handleOffer(Map<String, dynamic> offerData, String consultationId) async {
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(offerData['sdp'], offerData['type']),
    );

    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    _signaling.emitAnswer(consultationId, answer.toMap());
  }

  Future<void> _handleAnswer(Map<String, dynamic> answerData) async {
    if (_peerConnection == null) return;
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(answerData['sdp'], answerData['type']),
    );
  }

  Future<void> _handleIceCandidate(Map<String, dynamic> candidateData) async {
    if (_peerConnection == null) return;
    await _peerConnection!.addCandidate(
      RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      ),
    );
  }

  void toggleMute() {
    if (_localStream != null) {
      final audioTrack = _localStream!.getAudioTracks()[0];
      audioTrack.enabled = !audioTrack.enabled;
    }
  }

  void toggleVideo() {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks()[0];
      videoTrack.enabled = !videoTrack.enabled;
    }
  }

  Future<void> switchCamera() async {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks()[0];
      await Helper.switchCamera(videoTrack);
    }
  }

  void dispose() {
    _localStream?.getTracks().forEach((track) {
      track.stop();
    });
    _localStream?.dispose();
    _remoteStream?.dispose();
    _peerConnection?.dispose();
    _remoteStreamController.close();
    _connectionStateController.close();
  }
}
