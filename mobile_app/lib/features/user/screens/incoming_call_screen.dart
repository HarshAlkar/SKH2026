import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/signaling_service.dart';
import '../../../core/services/permission_dialog_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../features/user/services/doctor_service.dart';
import 'call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final String consultationId;
  final String callerName;
  final String callType;
  final int? callerUserId;

  const IncomingCallScreen({
    super.key,
    required this.consultationId,
    required this.callerName,
    required this.callType,
    this.callerUserId,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  bool _accepting = false;

  Future<void> _accept() async {
    if (_accepting) return;

    final isVideo = widget.callType.toUpperCase() == 'VIDEO';
    try {
      // Ask for camera/mic BEFORE showing Joining so a permission hang
      // cannot leave this screen stuck on the spinner.
      final allowed = await PermissionDialogService.ensureCallPermissions(
        context,
        isVideo: isVideo,
      );
      if (!mounted) return;
      if (!allowed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isVideo
                  ? 'Camera and microphone permission required to accept the call.'
                  : 'Microphone permission required to accept the call.',
            ),
          ),
        );
        return;
      }

      setState(() => _accepting = true);

      final signaling = SignalingService();
      signaling.emitAccept(
        widget.consultationId,
        callerUserId: widget.callerUserId?.toString(),
      );
      // Join the room immediately so the caller can offer while we navigate.
      signaling.joinRoom(widget.consultationId);

      // Do not block UI on backend accept (token/network can hang Accept).
      // ignore: unawaited_futures
      DoctorService().acceptConsultation(widget.consultationId).then((_) {}, onError: (_) {});
      // ignore: unawaited_futures
      NotificationService().cancelIncomingCall(widget.consultationId);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CallScreen(
            consultationId: widget.consultationId,
            doctorName: widget.callerName,
            isVideo: isVideo,
            isOfferer: false,
            peerUserId: widget.callerUserId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _accepting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not join the call. Please try again.')),
      );
    }
  }

  void _decline() {
    SignalingService().emitReject(
      widget.consultationId,
      receiverId: widget.callerUserId?.toString(),
    );
    NotificationService().cancelIncomingCall(widget.consultationId);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E293B),
              Color(0xFF334155),
              Color(0xFF1E293B),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const SizedBox(height: 40),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.1),
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 80,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.callerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Incoming ${widget.callType.toUpperCase() == 'VIDEO' ? 'Video' : 'Voice'} Call',
                    style: TextStyle(
                      color: AppColors.primary.withValues(alpha: 0.8),
                      fontSize: 16,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCallAction(
                    icon: Icons.close,
                    color: Colors.redAccent,
                    label: 'Decline',
                    onTap: _accepting ? null : _decline,
                  ),
                  _buildCallAction(
                    icon: _accepting
                        ? null
                        : (widget.callType.toUpperCase() == 'VIDEO'
                            ? Icons.videocam
                            : Icons.call),
                    color: Colors.greenAccent.shade700,
                    label: _accepting ? 'Joining…' : 'Accept',
                    onTap: _accepting ? null : _accept,
                    loading: _accepting,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallAction({
    required IconData? icon,
    required Color color,
    required String label,
    required VoidCallback? onTap,
    bool loading = false,
  }) {
    return Column(
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          elevation: 4,
          shadowColor: color.withValues(alpha: 0.4),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 72,
              height: 72,
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Icon(icon, color: Colors.white, size: 32),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}
