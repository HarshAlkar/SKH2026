import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../core/services/webrtc_service.dart';
import '../../../providers/consultation_provider.dart';

class VideoConsultationScreen extends StatefulWidget {
  final String consultationId;
  final bool isOfferer;

  const VideoConsultationScreen({
    super.key,
    required this.consultationId,
    this.isOfferer = false,
  });

  @override
  State<VideoConsultationScreen> createState() => _VideoConsultationScreenState();
}

class _VideoConsultationScreenState extends State<VideoConsultationScreen> {
  final _webrtcService = WebRTCService();
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isConnecting = true;
  String _connectionStatus = 'Connecting...';

  @override
  void initState() {
    super.initState();
    _initWebRTC();
  }

  Future<void> _initWebRTC() async {
    await [Permission.camera, Permission.microphone].request();

    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    await _webrtcService.init(widget.consultationId, isOfferer: widget.isOfferer);

    // Listen for remote stream to appear
    _webrtcService.onRemoteStream.listen((stream) {
      if (stream != null && mounted) {
        setState(() {
          _remoteRenderer.srcObject = stream;
          _isConnecting = false;
          _connectionStatus = 'Connected';
        });
      }
    });

    // Listen for connection state changes
    _webrtcService.onConnectionState.listen((state) {
      if (mounted) {
        setState(() {
          switch (state) {
            case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
              _connectionStatus = 'Connected';
              _isConnecting = false;
              break;
            case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
              _connectionStatus = 'Connecting...';
              break;
            case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
              _connectionStatus = 'Disconnected';
              break;
            case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
              _connectionStatus = 'Connection Failed';
              break;
            default:
              break;
          }
        });
      }
    });

    // Render local stream immediately
    if (mounted) {
      setState(() {
        _localRenderer.srcObject = _webrtcService.localStream;
      });
    }
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _webrtcService.dispose();
    super.dispose();
  }

  void _onHangup() async {
    await context.read<ConsultationProvider>().endConsultation(widget.consultationId);
    if (mounted) Navigator.pop(context);
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

  void _onSwitchCamera() {
    _webrtcService.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2A7DE1);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Remote video (full screen)
            Positioned.fill(
              child: _remoteRenderer.srcObject != null
                  ? RTCVideoView(
                      _remoteRenderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  : Container(
                      color: const Color(0xFF1E293B),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(color: Colors.white),
                            const SizedBox(height: 16),
                            Text(
                              _connectionStatus,
                              style: const TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            // 2. Top header overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.white,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Video Consultation',
                            style: TextStyle(
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
                                decoration: BoxDecoration(
                                  color: _isConnecting ? Colors.orange : const Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _connectionStatus,
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
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          Icon(Icons.signal_cellular_alt, color: primaryBlue, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Live',
                            style: TextStyle(
                              color: primaryBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Local video (PiP overlay)
            Positioned(
              top: 90,
              right: 20,
              child: GestureDetector(
                onTap: _onSwitchCamera,
                child: Container(
                  width: 100,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.teal.shade700,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _isCameraOff
                        ? const Center(
                            child: Icon(Icons.videocam_off, color: Colors.white, size: 40),
                          )
                        : (_localRenderer.srcObject != null
                            ? RTCVideoView(
                                _localRenderer,
                                mirror: true,
                                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                              )
                            : const Center(
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )),
                  ),
                ),
              ),
            ),

            // 4. Bottom control panel
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.only(top: 20, bottom: 30, left: 16, right: 16),
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
                    _buildControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic_none,
                      label: 'MUTE',
                      isActive: _isMuted,
                      onTap: _onToggleMute,
                    ),
                    _buildControlButton(
                      icon: _isCameraOff ? Icons.videocam_off : Icons.videocam_outlined,
                      label: 'CAMERA',
                      isActive: _isCameraOff,
                      onTap: _onToggleCamera,
                    ),
                    _buildControlButton(
                      icon: Icons.flip_camera_ios,
                      label: 'FLIP',
                      onTap: _onSwitchCamera,
                    ),
                    // End Call Button
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: _onHangup,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFEF4444).withOpacity(0.1) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? const Color(0xFFEF4444) : const Color(0xFFE5E7EB),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? const Color(0xFFEF4444) : const Color(0xFF374151),
              size: 24,
            ),
          ),
        ),
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
    );
  }
}
