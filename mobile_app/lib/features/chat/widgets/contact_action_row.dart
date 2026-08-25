import 'package:flutter/material.dart';
import '../../../core/services/call_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../screens/chat_screen.dart';

class ContactActionRow extends StatelessWidget {
  final String peerName;
  final int peerUserId;
  final bool isVideoEnabled;
  final int? doctorId;
  final int? patientId;
  final int? ashaId;
  final bool compact;

  const ContactActionRow({
    super.key,
    required this.peerName,
    required this.peerUserId,
    this.isVideoEnabled = true,
    this.doctorId,
    this.patientId,
    this.ashaId,
    this.compact = false,
  });

  Future<void> _startCall(BuildContext context, {required bool isVideo}) async {
    await CallLauncher.start(
      context: context,
      peerName: peerName,
      receiverUserId: peerUserId.toString(),
      isVideo: isVideo,
      doctorId: doctorId,
      patientId: patientId,
      ashaId: ashaId,
    );
  }

  void _openChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          peerUserId: peerUserId,
          peerName: peerName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (peerUserId <= 0) return const SizedBox.shrink();
    if (compact) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            tooltip: 'Video call',
            onPressed: () => _startCall(context, isVideo: true),
            icon: const Icon(Icons.videocam, color: AppColors.primary),
          ),
          IconButton(
            tooltip: 'Audio call',
            onPressed: () => _startCall(context, isVideo: false),
            icon: const Icon(Icons.phone, color: AppColors.primary),
          ),
          IconButton(
            tooltip: 'Chat',
            onPressed: () => _openChat(context),
            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _startCall(context, isVideo: true),
            icon: const Icon(Icons.videocam_outlined, size: 16),
            label: const Text('Video', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _startCall(context, isVideo: false),
            icon: const Icon(Icons.phone_outlined, size: 16),
            label: const Text('Audio', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _openChat(context),
            icon: const Icon(Icons.chat_bubble_outline, size: 16),
            label: const Text('Chat', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F766E),
              side: const BorderSide(color: Color(0xFF0F766E)),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}

int? parseContactId(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

String contactVillage(Map<String, dynamic> user) {
  final details = user['profile_details'] is Map
      ? Map<String, dynamic>.from(user['profile_details'] as Map)
      : <String, dynamic>{};
  return (details['assigned_village'] ?? user['village'] ?? '').toString();
}

String contactPhone(Map<String, dynamic> user) {
  return (user['phone_number'] ?? user['phone'] ?? '').toString();
}

String contactName(Map<String, dynamic> user) {
  return (user['name'] ?? user['full_name'] ?? 'Unknown').toString();
}
