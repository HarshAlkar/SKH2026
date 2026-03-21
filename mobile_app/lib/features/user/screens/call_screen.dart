import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/services/webrtc_service.dart';
import '../../user/services/doctor_service.dart';

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

class _CallScreenState extends State<CallScreen> {
  final _webrtcService = WebRTCService();
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  bool _isMuted = false;
  bool _isCameraOff = false;

  @override
  void initState() {
    super.initState();
    _initWebRTC();
  }

  Future<void> _initWebRTC() async {
    // Request permissions
    await [Permission.camera, Permission.microphone].request();

    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    await _webrtcService.init(widget.consultationId, isOfferer: widget.isOfferer);
    
    _webrtcService.onRemoteStream.listen((stream) {
      if (stream != null && mounted) {
        setState(() {
          _remoteRenderer.srcObject = stream;
        });
      }
    });

    if (mounted) {
      setState(() {
        _localRenderer.srcObject = _webrtcService.localStream;
      });
    }
  }

  @override
  void dispose() {
    _endConsultation();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _webrtcService.dispose();
    super.dispose();
  }

  void _endConsultation() {
    final doctorService = DoctorService();
    doctorService.endConsultation(widget.consultationId);
  }

  void _onHangup() {
    Navigator.pop(context);
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote Video
          Center(
            child: _remoteRenderer.srcObject != null
              ? RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 20),
                    Text(
                      'Connecting to ${widget.doctorName}...',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
          ),

          // Local Video (Overlay)
          Positioned(
            right: 20,
            top: 40,
            child: widget.isVideo 
              ? Container(
                  width: 120,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                  ),
                )
              : Container(),
          ),

          // Top Side Controls (Switch camera)
          Positioned(
            left: 20,
            top: 40,
            child: widget.isVideo 
              ? _buildCallAction(
                  icon: Icons.flip_camera_ios,
                  color: Colors.white24,
                  onPressed: _onSwitchCamera,
                )
              : Container(),
          ),

          // Call Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCallAction(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  color: _isMuted ? Colors.red : Colors.white24,
                  onPressed: _onToggleMute,
                ),
                _buildCallAction(
                  icon: Icons.call_end,
                  color: Colors.red,
                  onPressed: _onHangup,
                  size: 32,
                ),
                _buildCallAction(
                  icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                  color: _isCameraOff ? Colors.red : Colors.white24,
                  onPressed: _onToggleCamera,
                ),
              ],
            ),
          ),

          // Top Info
          Positioned(
            top: 50,
            left: 80, // Moved to not overlap with switch camera
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctorName,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Consultation In Progress',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallAction({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    double size = 24,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }
}
