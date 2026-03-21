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

  final List<RTCIceCandidate> _remoteCandidatesQueue = [];
  bool _isRemoteDescriptionSet = false;

  Future<void> init(String consultationId, {bool isOfferer = true}) async {
    _signaling.joinRoom(consultationId);
    
    // Listen for peer joined to trigger the call if we are offerer
    _signaling.onPeerJoined((data) async {
      print('Signaling: Peer joined ${data['socketId']}');
      if (isOfferer) {
        print('Signaling: Offerer detected peer, starting call...');
        await startCall(consultationId);
      }
    });

    _signaling.onOffer((data) async {
      if (!isOfferer) {
        print('Signaling: Received offer');
        await _setupPeerConnection(consultationId);
        await _handleOffer(data['offer'], consultationId);
      }
    });

    _signaling.onAnswer((data) async {
      if (isOfferer) {
        print('Signaling: Received answer');
        await _handleAnswer(data['answer']);
      }
    });

    _signaling.onIceCandidate((data) async {
      print('Signaling: Received ICE candidate');
      final candidateMap = Map<String, dynamic>.from(data['candidate']);
      final candidate = RTCIceCandidate(
        candidateMap['candidate'],
        candidateMap['sdpMid'],
        candidateMap['sdpMLineIndex'],
      );

      if (_isRemoteDescriptionSet) {
        await _peerConnection?.addCandidate(candidate);
      } else {
        _remoteCandidatesQueue.add(candidate);
      }
    });
  }

  Future<void> _setupPeerConnection(String consultationId) async {
    if (_peerConnection != null) return;

    final Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ]
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection!.onIceCandidate = (candidate) {
      _signaling.emitIceCandidate(consultationId, candidate.toMap());
    };

    _peerConnection!.onAddStream = (stream) {
      print('WebRTC: Remote stream added');
      _remoteStream = stream;
      _remoteStreamController.add(stream);
    };

    _peerConnection!.onConnectionState = (state) {
      print('WebRTC: Connection state changed to $state');
      _connectionStateController.add(state);
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': true,
      });
      
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });
    } catch (e) {
      print('Error getting user media: $e');
    }
  }

  Future<void> startCall(String consultationId, {bool video = true}) async {
    await _setupPeerConnection(consultationId);

    RTCSessionDescription offer = await _peerConnection!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': true,
    });
    await _peerConnection!.setLocalDescription(offer);

    _signaling.emitOffer(consultationId, offer.toMap());
  }

  Future<void> _handleOffer(Map<String, dynamic> offerData, String consultationId) async {
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(offerData['sdp'], offerData['type']),
    );
    _isRemoteDescriptionSet = true;
    await _processQueuedCandidates();

    RTCSessionDescription answer = await _peerConnection!.createAnswer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': true,
    });
    await _peerConnection!.setLocalDescription(answer);

    _signaling.emitAnswer(consultationId, answer.toMap());
  }

  Future<void> _handleAnswer(Map<String, dynamic> answerData) async {
    if (_peerConnection == null) return;
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(answerData['sdp'], answerData['type']),
    );
    _isRemoteDescriptionSet = true;
    await _processQueuedCandidates();
  }

  Future<void> _processQueuedCandidates() async {
    for (var candidate in _remoteCandidatesQueue) {
      await _peerConnection?.addCandidate(candidate);
    }
    _remoteCandidatesQueue.clear();
  }

  void toggleMute() {
    if (_localStream != null) {
      for (var track in _localStream!.getAudioTracks()) {
        track.enabled = !track.enabled;
      }
    }
  }

  void toggleVideo() {
    if (_localStream != null) {
      for (var track in _localStream!.getVideoTracks()) {
        track.enabled = !track.enabled;
      }
    }
  }

  Future<void> switchCamera() async {
    if (_localStream != null && _localStream!.getVideoTracks().isNotEmpty) {
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
    _isRemoteDescriptionSet = false;
    _remoteCandidatesQueue.clear();
  }
}
