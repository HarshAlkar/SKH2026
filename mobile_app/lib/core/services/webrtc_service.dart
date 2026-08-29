import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../config/app_config.dart';
import 'signaling_service.dart';
import 'webrtc_signaling.dart';

class WebRTCService {
  final SignalingService _signaling = SignalingService();
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  bool _hungUp = false;
  bool _mediaStopped = false;
  bool _wantVideo = true;
  bool _isOfferer = true;
  bool _offerInFlight = false;
  bool _localOfferSent = false;
  bool _connected = false;
  bool _iceRestarted = false;
  int _session = 0;
  String? _lastRemoteSdp;

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
  Future<void>? _mediaOpenFuture;
  Future<void>? _pcSetupFuture;
  Map<String, dynamic>? _pendingOffer;

  bool get _isActiveSession => _session == _signaling.callEpoch && !_hungUp;

  Future<void> init(
    String consultationId, {
    bool isOfferer = true,
    bool video = true,
  }) async {
    // Drop any stale room from a previous call before starting fresh.
    final stale = _signaling.activeConsultationId;
    if (stale != null && stale != consultationId) {
      _signaling.leaveRoom(stale);
    }

    _session = _signaling.beginCallSession();
    _consultationId = consultationId;
    _hungUp = false;
    _mediaStopped = false;
    _wantVideo = video;
    _isOfferer = isOfferer;
    _offerInFlight = false;
    _localOfferSent = false;
    _connected = false;
    _iceRestarted = false;
    _lastRemoteSdp = null;
    _pendingOffer = null;
    _isRemoteDescriptionSet = false;
    _remoteCandidatesQueue.clear();

    await _tearDownPeerOnly();

    // Bind signaling and join the room BEFORE getUserMedia so an offer/ICE
    // that arrives while the camera starts is not dropped.
    _signaling.onPeerJoined((data) async {
      if (!_isActiveSession || !_isOfferer || _connected) return;
      debugPrint('Signaling: Peer joined ${data['socketId']} — sending offer');
      await startCall(consultationId, video: video);
    });

    _signaling.onRequestOffer((data) async {
      if (!_isActiveSession || !_isOfferer || _connected) return;
      debugPrint('Signaling: request-offer — resend existing offer if any');
      await startCall(consultationId, video: video);
    });

    _signaling.onOffer((data) async {
      if (!_isActiveSession || _isOfferer) return;
      final offer = signalingMap(data['offer']);
      if (offer == null) return;
      _pendingOffer = offer;
      await _answerPendingOffer(consultationId);
    });

    _signaling.onAnswer((data) async {
      if (!_isActiveSession || !_isOfferer) return;
      final answer = signalingMap(data['answer']);
      if (answer == null) return;
      debugPrint('Signaling: Received answer');
      await _handleAnswer(answer);
    });

    _signaling.onIceCandidate((data) async {
      if (!_isActiveSession) return;
      final candidate = _candidateFromPayload(data['candidate']);
      if (candidate == null) return;

      if (_peerConnection != null && _isRemoteDescriptionSet) {
        try {
          await _peerConnection!.addCandidate(candidate);
        } catch (e) {
          debugPrint('WebRTC addCandidate error: $e');
        }
      } else {
        _remoteCandidatesQueue.add(candidate);
      }
    });

    _signaling.joinRoom(consultationId);

    await _openLocalMedia(video: video);

    if (!_isOfferer) {
      await _answerPendingOffer(consultationId);
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (_isActiveSession && !_connected && _lastRemoteSdp == null) {
          _signaling.emitRequestOffer(consultationId);
        }
      });
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (_isActiveSession && !_connected && _remoteStream == null) {
          _signaling.emitRequestOffer(consultationId);
        }
      });
      Future<void>.delayed(const Duration(seconds: 5), () {
        if (_isActiveSession && !_connected && _remoteStream == null) {
          _signaling.emitRequestOffer(consultationId);
        }
      });
    }
  }

  Future<void> _openLocalMedia({bool video = true}) async {
    if (_localStream != null) return;
    if (_mediaOpenFuture != null) {
      await _mediaOpenFuture;
      return;
    }
    _mediaOpenFuture = _doOpenLocalMedia(video: video);
    try {
      await _mediaOpenFuture;
    } finally {
      _mediaOpenFuture = null;
    }
  }

  Future<void> _doOpenLocalMedia({required bool video}) async {
    if (_localStream != null) return;
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': video
            ? {
                'facingMode': 'user',
                'width': {'ideal': 640},
                'height': {'ideal': 480},
              }
            : false,
      });
      _publishLocalStream();
      try {
        await Helper.setSpeakerphoneOn(true);
      } catch (_) {}
    } catch (e) {
      debugPrint('Error getting user media: $e');
      if (video) {
        try {
          _localStream = await navigator.mediaDevices.getUserMedia({
            'audio': true,
            'video': false,
          });
          _publishLocalStream();
        } catch (e2) {
          debugPrint('Audio-only fallback failed: $e2');
        }
      }
    }
  }

  void _publishLocalStream() {
    if (_localStream == null) return;
    for (final track in _localStream!.getTracks()) {
      track.enabled = true;
    }
    if (!_localStreamController.isClosed) {
      _localStreamController.add(_localStream);
    }
  }

  void _publishRemoteStream(MediaStream stream) {
    _remoteStream = stream;
    for (final track in stream.getTracks()) {
      track.enabled = true;
    }
    if (!_remoteStreamController.isClosed) {
      _remoteStreamController.add(stream);
    }
  }

  Future<void> _tearDownPeerOnly() async {
    _isRemoteDescriptionSet = false;
    _localOfferSent = false;
    _pcSetupFuture = null;
    try {
      await _peerConnection?.close();
      await _peerConnection?.dispose();
    } catch (_) {}
    _peerConnection = null;
  }

  Future<void> _setupPeerConnection(String consultationId) async {
    if (_peerConnection != null) return;
    if (_pcSetupFuture != null) {
      await _pcSetupFuture;
      return;
    }
    _pcSetupFuture = _doSetupPeerConnection(consultationId);
    try {
      await _pcSetupFuture;
    } finally {
      _pcSetupFuture = null;
    }
  }

  Future<void> _doSetupPeerConnection(String consultationId) async {
    if (_peerConnection != null) return;

    final Map<String, dynamic> configuration = {
      'iceServers': AppConfig.iceServers,
      'sdpSemantics': 'unified-plan',
      'iceCandidatePoolSize': 10,
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection!.onIceCandidate = (candidate) {
      if (!_isActiveSession) return;
      final raw = candidate.candidate;
      if (raw == null || raw.isEmpty) return;
      _signaling.emitIceCandidate(consultationId, candidate.toMap());
    };

    _peerConnection!.onTrack = (event) {
      debugPrint(
        'WebRTC: onTrack kind=${event.track.kind} streams=${event.streams.length}',
      );
      if (event.streams.isNotEmpty) {
        _publishRemoteStream(event.streams[0]);
        return;
      }
      // Unified-plan / some Android builds deliver a track with empty streams.
      // Without this, the answerer (often the patient) never shows remote video.
      () async {
        try {
          final stream = _remoteStream ??
              await createLocalMediaStream('remote_${event.track.id}');
          final already = stream.getTracks().any((t) => t.id == event.track.id);
          if (!already) {
            await stream.addTrack(event.track);
          }
          _publishRemoteStream(stream);
        } catch (e) {
          debugPrint('WebRTC: failed to attach remote track: $e');
        }
      }();
    };

    _peerConnection!.onAddStream = (stream) {
      debugPrint('WebRTC: Remote stream added');
      _publishRemoteStream(stream);
    };

    _peerConnection!.onConnectionState = (state) {
      debugPrint('WebRTC: Connection state changed to $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _connected = true;
      }
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed &&
          _isOfferer &&
          !_iceRestarted &&
          _isActiveSession) {
        _iceRestarted = true;
        _restartIce(consultationId);
        return;
      }
      if (!_connectionStateController.isClosed) {
        _connectionStateController.add(state);
      }
    };

    await _openLocalMedia(video: _wantVideo);
    _localStream?.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });
  }

  Future<void> startCall(
    String consultationId, {
    bool video = true,
    bool forceNew = false,
  }) async {
    if (!_isActiveSession || _connected) return;
    if (_offerInFlight) return;

    // A second peer-joined / request-offer must NOT destroy the first PC.
    // That discarded ICE and made the callee's answer apply to a dead offer.
    if (!forceNew &&
        _peerConnection != null &&
        _localOfferSent &&
        !_isRemoteDescriptionSet) {
      try {
        final local = await _peerConnection!.getLocalDescription();
        if (local != null) {
          _signaling.emitOffer(consultationId, local.toMap());
          debugPrint('WebRTC: re-sent existing offer for $consultationId');
          return;
        }
      } catch (e) {
        debugPrint('WebRTC re-send offer error: $e');
      }
    }

    _offerInFlight = true;
    try {
      if (forceNew) {
        await _tearDownPeerOnly();
        _remoteCandidatesQueue.clear();
      }
      await _setupPeerConnection(consultationId);

      final RTCSessionDescription offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': video,
      });
      await _peerConnection!.setLocalDescription(offer);
      _localOfferSent = true;
      _signaling.emitOffer(consultationId, offer.toMap());
      debugPrint('WebRTC: offer sent for $consultationId');
    } catch (e) {
      debugPrint('WebRTC startCall error: $e');
    } finally {
      _offerInFlight = false;
    }
  }

  Future<void> _restartIce(String consultationId) async {
    if (_peerConnection == null || !_isActiveSession) return;
    debugPrint('WebRTC: ICE restart');
    try {
      final offer = await _peerConnection!.createOffer({
        'iceRestart': true,
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': _wantVideo,
      });
      await _peerConnection!.setLocalDescription(offer);
      _localOfferSent = true;
      _isRemoteDescriptionSet = false;
      _signaling.emitOffer(consultationId, offer.toMap());
    } catch (e) {
      debugPrint('WebRTC ICE restart error: $e');
    }
  }

  Future<void> _answerPendingOffer(String consultationId) async {
    final offer = _pendingOffer;
    if (offer == null || !_isActiveSession || _isOfferer) return;
    final sdp = offer['sdp']?.toString();
    if (sdp != null && sdp == _lastRemoteSdp && _connected) return;

    try {
      await _setupPeerConnection(consultationId);
      await _handleOffer(offer, consultationId);
      if (_lastRemoteSdp == sdp) {
        _pendingOffer = null;
      }
    } catch (e) {
      debugPrint('WebRTC answer offer error: $e');
    }
  }

  Future<void> _handleOffer(Map<String, dynamic> offerData, String consultationId) async {
    if (_peerConnection == null) return;
    final sdp = offerData['sdp']?.toString();
    final type = offerData['type']?.toString() ?? 'offer';
    if (sdp == null || sdp.isEmpty) return;
    if (sdp == _lastRemoteSdp && _isRemoteDescriptionSet) {
      debugPrint('WebRTC: skip duplicate offer');
      return;
    }

    await _peerConnection!.setRemoteDescription(RTCSessionDescription(sdp, type));
    _lastRemoteSdp = sdp;
    _isRemoteDescriptionSet = true;
    await _processQueuedCandidates();

    final RTCSessionDescription answer = await _peerConnection!.createAnswer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': true,
    });
    await _peerConnection!.setLocalDescription(answer);
    _signaling.emitAnswer(consultationId, answer.toMap());
    debugPrint('WebRTC: answer sent for $consultationId');
  }

  Future<void> _handleAnswer(Map<String, dynamic> answerData) async {
    if (_peerConnection == null) return;
    final sdp = answerData['sdp']?.toString();
    final type = answerData['type']?.toString() ?? 'answer';
    if (sdp == null || sdp.isEmpty) return;
    try {
      await _peerConnection!.setRemoteDescription(RTCSessionDescription(sdp, type));
      _isRemoteDescriptionSet = true;
      await _processQueuedCandidates();
    } catch (e) {
      debugPrint('WebRTC setRemoteDescription(answer) error: $e');
    }
  }

  RTCIceCandidate? _candidateFromPayload(dynamic raw) {
    final map = signalingMap(raw);
    if (map == null) return null;
    final candidate = iceCandidateString(map['candidate']);
    if (candidate == null) return null;
    return RTCIceCandidate(
      candidate,
      map['sdpMid']?.toString(),
      iceLineIndex(map['sdpMLineIndex']),
    );
  }

  Future<void> _processQueuedCandidates() async {
    final queued = List<RTCIceCandidate>.from(_remoteCandidatesQueue);
    _remoteCandidatesQueue.clear();
    for (final candidate in queued) {
      try {
        await _peerConnection?.addCandidate(candidate);
      } catch (e) {
        debugPrint('WebRTC queued addCandidate error: $e');
      }
    }
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
    await _tearDownPeerOnly();
    _localStream = null;
    _remoteStream = null;
    // Let the OS release the camera before the next call.
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  Future<void> hangup({bool notifyPeer = true}) async {
    if (_hungUp) return;
    _hungUp = true;
    final room = _consultationId;
    if (notifyPeer && room != null) {
      _signaling.emitHangup(room);
      _signaling.leaveRoom(room);
    } else if (room != null) {
      _signaling.leaveRoom(room);
    }
    await pauseMedia();
  }

  Future<void> dispose() async {
    final epoch = _session;
    if (!_hungUp) {
      await hangup(notifyPeer: false);
    } else {
      await pauseMedia();
    }
    _signaling.endCallSession(epoch);
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
