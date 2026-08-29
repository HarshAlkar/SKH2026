import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/user/screens/call_screen.dart';
import '../../features/user/services/doctor_service.dart';
import '../../providers/auth_provider.dart';
import '../config/app_config.dart';
import 'permission_dialog_service.dart';
import 'signaling_service.dart';

class CallLauncher {
  static Future<void> start({
    required BuildContext context,
    required String peerName,
    required String receiverUserId,
    required bool isVideo,
    int? doctorId,
    int? patientId,
    int? ashaId,
    bool isEmergency = false,
  }) async {
    final allowed = await PermissionDialogService.ensureCallPermissions(
      context,
      isVideo: isVideo,
    );
    if (!allowed || !context.mounted) return;

    final signaling = SignalingService();
    if (!signaling.isConnected) {
      final auth = context.read<AuthProvider>();
      final uid = auth.user?.id.toString();
      if (uid != null) signaling.connect(uid);
      for (var i = 0; i < 15 && !signaling.isConnected; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      if (!signaling.isConnected && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Calls server offline (${AppConfig.signalingServerUrl}). '
              'Check signaling is running, save your server IP, then log in again.',
            ),
          ),
        );
        return;
      }
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final consultation = await DoctorService().startConsultation(
        doctorId: doctorId,
        patientId: patientId,
        ashaId: ashaId,
        callType: isVideo ? 'VIDEO' : 'AUDIO',
        isEmergency: isEmergency,
      );

      if (!context.mounted) return;
      final auth = context.read<AuthProvider>();
      signaling.sendCallRequest(
        receiverId: receiverUserId,
        consultationId: consultation['id'].toString(),
        callerName: auth.user?.name ?? 'Caller',
        callType: isVideo ? 'VIDEO' : 'AUDIO',
        callerUserId: auth.user?.id.toString(),
      );

      Navigator.pop(context);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
            consultationId: consultation['id'].toString(),
            doctorName: peerName,
            isVideo: isVideo,
            isOfferer: true,
            peerUserId: int.tryParse(receiverUserId),
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        final msg = e.toString().toLowerCase();
        final friendly = msg.contains('invalid token') || msg.contains('unauthorized')
            ? 'Session expired. Log out and log in again, then retry the call.'
            : 'Could not start call: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendly)),
        );
      }
    }
  }
}
