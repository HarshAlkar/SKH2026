import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/user/screens/call_screen.dart';
import '../../features/user/services/doctor_service.dart';
import '../../providers/auth_provider.dart';
import 'signaling_service.dart';

class CallLauncher {
  static Future<void> start({
    required BuildContext context,
    required String peerName,
    required String receiverUserId,
    required bool isVideo,
    int? doctorId,
    int? patientId,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final consultation = await DoctorService().startConsultation(
        doctorId: doctorId,
        patientId: patientId,
        callType: isVideo ? 'VIDEO' : 'AUDIO',
      );

      if (!context.mounted) return;
      final auth = context.read<AuthProvider>();
      SignalingService().sendCallRequest(
        receiverId: receiverUserId,
        consultationId: consultation['id'].toString(),
        callerName: auth.user?.name ?? 'Caller',
        callType: isVideo ? 'VIDEO' : 'AUDIO',
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
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start call: $e')),
        );
      }
    }
  }
}
