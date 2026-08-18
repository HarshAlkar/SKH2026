import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../core/services/webrtc_service.dart';
import '../../../core/services/signaling_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../user/services/doctor_service.dart';
import '../../../main.dart';

class CallScreen extends StatefulWidget {
  final String consultationId;
  final String doctorName;
  final bool isVideo;
  final bool isOfferer;

  const CallScreen({
    super.key,
    required this.consultationId,
    required this.doctorName,
    this.isVideo = true,
    this.isOfferer = true,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _ChatLine {
  final String text;
  final String senderId;
  final bool pending;

  const _ChatLine({
    required this.text,
    required this.senderId,
    this.pending = false,
  });
}

class _CallScreenState extends State<CallScreen> {
  final _webrtcService = WebRTCService();
  final _signaling = SignalingService();
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  final _chatController = TextEditingController();
  final _chatScroll = ScrollController();
  final _pendingMessages = <String>[];
  final _messages = <_ChatLine>[];

  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _showVideo = true;
  bool _hasLeft = false;
  bool _inChat = false;
  bool _renderersReady = false;
  bool _hasLocalVideo = false;
  String? _statusBanner;
  DateTime? _startedAt;

  Timer? _disconnectTimer;
  Timer? _tick;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<RTCPeerConnectionState>? _pcSub;
  StreamSubscription<MediaStream?>? _remoteSub;
  StreamSubscription<MediaStream?>? _localSub;

  String _myId = 'me';

  String get _elapsed {
    if (_startedAt == null) return '00:00';
    final d = DateTime.now().difference(_startedAt!);
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_inChat) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _myId = context.read<AuthProvider>().user?.id.toString() ?? 'me';
    });
    _initWebRTC();
  }

  Future<void> _initWebRTC() async {
    await [Permission.camera, Permission.microphone].request();

    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    if (!mounted) return;
    _renderersReady = true;

    await _webrtcService.init(
      widget.consultationId,
      isOfferer: widget.isOfferer,
      video: widget.isVideo,
    );

    _signaling.onHangup((_) => _leaveCall(notifyPeer: false));
    _signaling.onRejected((_) => _leaveCall(notifyPeer: false));
    _signaling.onFallbackToChat((_) {
      _switchToChat('Other person switched to chat. Consultation is still active.');
    });
    _signaling.onNewMessage(_onIncomingChat);
    _signaling.onDisconnected(() {
      _switchToChat('Connection lost. Switched to chat — call is not ended.');
    });
    _signaling.onReconnected(() {
      if (!mounted || _hasLeft) return;
      _flushPendingMessages();
      setState(() {
        _statusBanner = 'Reconnected. You can keep chatting.';
      });
    });

    _localSub = _webrtcService.onLocalStream.listen((stream) {
      if (stream != null && mounted && _showVideo) {
        setState(() {
          _localRenderer.srcObject = stream;
          _hasLocalVideo = true;
        });
      }
    });

    _remoteSub = _webrtcService.onRemoteStream.listen((stream) {
      if (stream != null && mounted && _showVideo) {
        setState(() {
          _remoteRenderer.srcObject = stream;
        });
      }
    });

    _pcSub = _webrtcService.onConnectionState.listen((state) {
      if (!mounted || _hasLeft || _inChat) return;
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _disconnectTimer?.cancel();
        _disconnectTimer = Timer(const Duration(seconds: 3), () {
          if (!_hasLeft && !_inChat) {
            _switchToChat('Video dropped. Switched to chat — call is not ended.');
          }
        });
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _switchToChat('Video failed. Switched to chat — call is not ended.');
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _disconnectTimer?.cancel();
      }
    });

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.isEmpty ||
          results.every((r) => r == ConnectivityResult.none);
      if (offline) {
        _switchToChat('Internet went off. Switched to chat — call is not ended.');
      }
    });

    if (mounted && _webrtcService.localStream != null) {
      setState(() {
        _localRenderer.srcObject = _webrtcService.localStream;
        _hasLocalVideo = true;
      });
    }
  }

  void _onIncomingChat(Map<String, dynamic> data) {
    if (!mounted) return;
    final senderId = data['senderId']?.toString() ?? '';
    if (senderId == _myId) return;
    final text = data['text']?.toString() ?? '';
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatLine(text: text, senderId: senderId));
    });
    _scrollChat();
  }

  void _flushPendingMessages() {
    for (final text in _pendingMessages) {
      _signaling.sendMessage(
        consultationId: widget.consultationId,
        text: text,
        senderId: _myId,
      );
    }
    _pendingMessages.clear();
    setState(() {
      for (var i = 0; i < _messages.length; i++) {
        final line = _messages[i];
        if (line.pending) {
          _messages[i] = _ChatLine(text: line.text, senderId: line.senderId);
        }
      }
    });
  }

  Future<void> _switchToChat(String reason) async {
    if (!mounted || _hasLeft || _inChat) return;
    _disconnectTimer?.cancel();
    _inChat = true;
    _showVideo = false;

    setState(() {
      _statusBanner = reason;
    });

    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;
    await Future.delayed(const Duration(milliseconds: 120));
    await _webrtcService.pauseMedia();

    if (_signaling.isConnected) {
      _signaling.emitFallbackToChat(widget.consultationId, 'network');
    }

    if (mounted) setState(() {});
  }

  Future<void> _leaveCall({bool notifyPeer = true}) async {
    if (_hasLeft) return;
    _hasLeft = true;
    _disconnectTimer?.cancel();
    _tick?.cancel();

    if (mounted) {
      setState(() {
        _showVideo = false;
        _inChat = false;
      });
    }

    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;
    await Future.delayed(const Duration(milliseconds: 150));

    try {
      await _webrtcService.hangup(notifyPeer: notifyPeer);
    } catch (_) {}

    _endConsultation();

    try {
      await _localRenderer.dispose();
      await _remoteRenderer.dispose();
    } catch (_) {}

    try {
      await _webrtcService.dispose();
    } catch (_) {}

    final nav = navigatorKey.currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
    } else if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _endConsultation() {
    DoctorService().endConsultation(widget.consultationId);
  }

  void _onHangup() {
    _leaveCall(notifyPeer: true);
  }

  void _sendChat() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    _chatController.clear();

    final connected = _signaling.isConnected;
    setState(() {
      _messages.add(_ChatLine(text: text, senderId: _myId, pending: !connected));
    });
    _scrollChat();

    if (connected) {
      _signaling.sendMessage(
        consultationId: widget.consultationId,
        text: text,
        senderId: _myId,
      );
    } else {
      _pendingMessages.add(text);
    }
  }

  void _scrollChat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScroll.hasClients) {
        _chatScroll.animateTo(
          _chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _disconnectTimer?.cancel();
    _tick?.cancel();
    _connectivitySub?.cancel();
    _pcSub?.cancel();
    _remoteSub?.cancel();
    _localSub?.cancel();
    _chatController.dispose();
    _chatScroll.dispose();
    if (!_hasLeft) {
      _localRenderer.srcObject = null;
      _remoteRenderer.srcObject = null;
      _webrtcService.dispose();
    }
    super.dispose();
  }

  void _onToggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _webrtcService.toggleMute();
    });
  }

  void _onToggleCamera() {
    setState(() {
      _isCameraOff = !_isCameraOff;
      _webrtcService.toggleVideo();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_inChat) {
      return _buildChatScaffold();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leaveCall(notifyPeer: true);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1E293B),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: _buildRemoteFeed()),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildHeader(),
              ),
              if (widget.isVideo)
                Positioned(
                  top: 88,
                  right: 16,
                  child: _buildLocalPip(),
                ),
              Positioned(
                left: 16,
                bottom: 168,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.doctorName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomPanel(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRemoteFeed() {
    if (_showVideo && _remoteRenderer.srcObject != null) {
      return RTCVideoView(
        _remoteRenderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      );
    }
    return Container(
      color: const Color(0xFF1E293B),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 120, color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 16),
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          Text(
            'Connecting to ${widget.doctorName}...',
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
            onPressed: _onHangup,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isVideo ? 'Video Consultation' : 'Audio Consultation',
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_elapsed · Live',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: const [
                Icon(Icons.signal_cellular_alt, color: AppColors.primary, size: 14),
                SizedBox(width: 4),
                Text(
                  'Stable',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildLocalPip() {
    return Container(
      width: 100,
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFF0F766E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_showVideo && _renderersReady && _hasLocalVideo && !_isCameraOff)
            RTCVideoView(
              _localRenderer,
              mirror: true,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            )
          else
            Center(
              child: Icon(
                _isCameraOff ? Icons.videocam_off : Icons.person,
                size: 48,
                color: Colors.white54,
              ),
            ),
          const Positioned(
            bottom: 8,
            left: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0x80000000),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'YOU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xE61E293B),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, color: Color(0xFFFBBF24), size: 16),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'If internet is slow, call will switch to chat.',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.only(top: 20, bottom: 20, left: 12, right: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _controlButton(
                icon: Icons.chat_bubble_outline,
                onTap: () => _switchToChat('Switched to chat. Consultation is still active.'),
              ),
              _controlButton(
                icon: Icons.flip_camera_ios_outlined,
                onTap: () => _webrtcService.switchCamera(),
              ),
              _controlButton(
                icon: _isMuted ? Icons.mic_off : Icons.mic_none,
                label: 'MUTE',
                isActive: _isMuted,
                onTap: _onToggleMute,
              ),
              if (widget.isVideo)
                _controlButton(
                  icon: _isCameraOff ? Icons.videocam_off : Icons.videocam_outlined,
                  label: 'CAMERA',
                  isActive: _isCameraOff,
                  onTap: _onToggleCamera,
                ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: _onHangup,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.call_end, color: Colors.white, size: 28),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'END CALL',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _controlButton({
    required IconData icon,
    required VoidCallback onTap,
    String label = '',
    bool isActive = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: label.isEmpty ? 48 : 56,
            height: label.isEmpty ? 48 : 56,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFF3F4F6) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
            ),
            child: Icon(icon, color: const Color(0xFF374151), size: 22),
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChatScaffold() {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leaveCall(notifyPeer: true);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.doctorName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Chat mode · consultation still active',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'End consultation',
              onPressed: _onHangup,
              icon: const Icon(Icons.call_end, color: Colors.red),
            ),
          ],
        ),
        body: Column(
          children: [
            if (_statusBanner != null)
              Container(
                width: double.infinity,
                color: const Color(0xFFFFF7ED),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  _statusBanner!,
                  style: const TextStyle(color: Color(0xFF9A3412), fontSize: 13),
                ),
              ),
            Expanded(
              child: _messages.isEmpty
                  ? const Center(
                      child: Text(
                        'Video paused. Type a message to continue the consultation.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      controller: _chatScroll,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final line = _messages[index];
                        final mine = line.senderId == _myId;
                        return Align(
                          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: mine ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              line.pending ? '${line.text}  (waiting for network)' : line.text,
                              style: TextStyle(
                                color: mine ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendChat(),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: IconButton(
                        onPressed: _sendChat,
                        icon: const Icon(Icons.send, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
