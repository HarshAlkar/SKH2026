import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../core/services/signaling_service.dart';
import '../../../core/theme/app_colors.dart';

class VideoCallScreen extends StatefulWidget {
  final String consultationId;
  final String userId;
  final bool isCalling;

  const VideoCallScreen({
    super.key,
    required this.consultationId,
    required this.userId,
    this.isCalling = false,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final SignalingService _signaling = SignalingService();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  bool _micOn = true;
  bool _camOn = true;

  @override
  void initState() {
    super.initState();
    _initWebRTC();
  }

  Future<void> _initWebRTC() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    _signaling.onLocalStream = (stream) {
      _localRenderer.srcObject = stream;
      setState(() {});
    };

    _signaling.onRemoteStream = (stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    };

    _signaling.init(widget.userId);
    await _signaling.openUserMedia();

    if (widget.isCalling) {
      await _signaling.startCall(widget.consultationId);
    } else {
      await _signaling.joinCall(widget.consultationId);
    }
  }

  @override
  void dispose() {
    _signaling.hangUp();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  void _toggleMic() {
    final stream = _localRenderer.srcObject;
    if (stream != null) {
      final audioTrack = stream.getAudioTracks()[0];
      audioTrack.enabled = !audioTrack.enabled;
      setState(() => _micOn = audioTrack.enabled);
    }
  }

  void _toggleCam() {
     final stream = _localRenderer.srcObject;
    if (stream != null) {
      final videoTrack = stream.getVideoTracks()[0];
      videoTrack.enabled = !videoTrack.enabled;
      setState(() => _camOn = videoTrack.enabled);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          // Remote Video
          Positioned.fill(
            child: _remoteRenderer.srcObject != null
                ? RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text('Waiting for peer...', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
          ),

          // Local Video (Small Overlay)
          Positioned(
            right: 20,
            bottom: 120,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24, width: 2),
                boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _camOn 
                  ? RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
                  : const Center(child: Icon(Icons.videocam_off, color: Colors.white24)),
              ),
            ),
          ),

          // Controls
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _controlButton(
                    onTap: _toggleMic,
                    isActive: _micOn,
                    icon: _micOn ? Icons.mic : Icons.mic_off,
                    color: Colors.white24,
                  ),
                  _controlButton(
                     onTap: () => Navigator.pop(context),
                     isActive: true,
                     icon: Icons.call_end,
                     color: Colors.redAccent,
                  ),
                  _controlButton(
                    onTap: _toggleCam,
                    isActive: _camOn,
                    icon: _camOn ? Icons.videocam : Icons.videocam_off,
                    color: Colors.white24,
                  ),
                ],
              ),
            ),
          ),
          
          // Consultation ID Label
          Positioned(
            top: 60,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
              child: Text(
                'Room: ${widget.consultationId}', 
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlButton({required VoidCallback onTap, required bool isActive, required IconData icon, required Color color}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
