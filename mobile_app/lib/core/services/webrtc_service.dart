import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../config/app_config.dart';
import 'signaling_service.dart';

class WebRTCService {
  final SignalingService _signaling = SignalingService();
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  bool _hungUp = false;
  bool _mediaStopped = false;
  bool _wantVideo = true;

  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  final _localStreamController = StreamController<MediaStream?>.broadcast();
  Stream<MediaStream?> get onLocalStream => _localStreamController.stream;

  final _remoteStreamController = StreamController<MediaStream?>.broadcast();
  Stream<MediaStream?> get onRemoteStream => _remoteStreamController.stream;

  final _connectionStateController = StreamController<RTCPeerConnectionState>.broadcast();
  Stream<RTCPeerConnectionState> get onConnectionState => _connectionStateController.stream;

  final List<RTCIceCandidate> _remoteCandidatesQueue = [];
  bool _isRemoteDescriptionSet = false;
  String? _consultationId;

  Future<void> init(
    String consultationId, {
    bool isOfferer = true,
    bool video = true,
  }) async {
    _consultationId = consultationId;
    _hungUp = false;
    _mediaStopped = false;
    _wantVideo = video;

    await _openLocalMedia(video: video);

    _signaling.onPeerJoined((data) async {
      print('Signaling: Peer joined ${data['socketId']}');
      if (isOfferer) {
        print('Signaling: Offerer detected peer, starting call...');
        await startCall(consultationId, video: video);
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

    _signaling.joinRoom(consultationId);
  }

  Future<void> _openLocalMedia({bool video = true}) async {
    if (_localStream != null) return;
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': video,
      });
      if (!_localStreamController.isClosed) {
        _localStreamController.add(_localStream);
      }
    } catch (e) {
      print('Error getting user media: $e');
    }
  }

  Future<void> _setupPeerConnection(String consultationId) async {
    if (_peerConnection != null) return;

    final Map<String, dynamic> configuration = {
      'iceServers': AppConfig.iceServers,
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection!.onIceCandidate = (candidate) {
      _signaling.emitIceCandidate(consultationId, candidate.toMap());
    };

    _peerConnection!.onAddStream = (stream) {
      print('WebRTC: Remote stream added');
      _remoteStream = stream;
      if (!_remoteStreamController.isClosed) {
        _remoteStreamController.add(stream);
      }
    };

    _peerConnection!.onConnectionState = (state) {
      print('WebRTC: Connection state changed to $state');
      if (!_connectionStateController.isClosed) {
        _connectionStateController.add(state);
      }
    };

    await _openLocalMedia(video: _wantVideo);
    _localStream?.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });
  }

  Future<void> startCall(String consultationId, {bool video = true}) async {
    await _setupPeerConnection(consultationId);

    RTCSessionDescription offer = await _peerConnection!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': video,
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

  Future<void> pauseMedia() async {
    if (_mediaStopped) return;
    _mediaStopped = true;
    try {
      Helper.setSpeakerphoneOn(false);
    } catch (_) {}
    _localStream?.getTracks().forEach((track) {
      track.stop();
    });
    await _localStream?.dispose();
    await _remoteStream?.dispose();
    await _peerConnection?.close();
    await _peerConnection?.dispose();
    _localStream = null;
    _remoteStream = null;
    _peerConnection = null;
    _isRemoteDescriptionSet = false;
    _remoteCandidatesQueue.clear();
  }

  Future<void> hangup({bool notifyPeer = true}) async {
    if (_hungUp) return;
    _hungUp = true;
    if (notifyPeer && _consultationId != null) {
      _signaling.emitHangup(_consultationId!);
      _signaling.leaveRoom(_consultationId!);
    }
    await pauseMedia();
  }

  Future<void> dispose() async {
    if (!_hungUp) {
      await hangup(notifyPeer: false);
    } else {
      await pauseMedia();
    }
    _signaling.clearCallListeners();
    if (!_localStreamController.isClosed) {
      await _localStreamController.close();
    }
    if (!_remoteStreamController.isClosed) {
      await _remoteStreamController.close();
    }
    if (!_connectionStateController.isClosed) {
      await _connectionStateController.close();
    }
  }
}
