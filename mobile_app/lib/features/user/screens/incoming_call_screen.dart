import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/signaling_service.dart';
import '../../../core/services/permission_dialog_service.dart';
import '../../../core/services/notification_service.dart';
import 'call_screen.dart';

class IncomingCallScreen extends StatelessWidget {
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

  Future<void> _accept(BuildContext context) async {
    final isVideo = callType == 'VIDEO';
    final allowed = await PermissionDialogService.ensureCallPermissions(
      context,
      isVideo: isVideo,
    );
    if (!allowed || !context.mounted) return;
    await NotificationService().cancelIncomingCall(consultationId);
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          consultationId: consultationId,
          doctorName: callerName,
          isVideo: isVideo,
          isOfferer: false,
          peerUserId: callerUserId,
        ),
      ),
    );
  }

  void _decline(BuildContext context) {
    SignalingService().emitReject(consultationId);
    NotificationService().cancelIncomingCall(consultationId);
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
                    callerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Incoming ${callType == 'VIDEO' ? 'Video' : 'Voice'} Call',
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
                    onTap: () => _decline(context),
                  ),
                  _buildCallAction(
                    icon: callType == 'VIDEO' ? Icons.videocam : Icons.call,
                    color: Colors.greenAccent.shade700,
                    label: 'Accept',
                    onTap: () => _accept(context),
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
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
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
