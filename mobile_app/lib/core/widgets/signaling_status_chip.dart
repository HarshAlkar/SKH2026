import 'package:flutter/material.dart';
import '../services/signaling_service.dart';
import '../config/app_config.dart';

/// Compact chip showing whether Socket.IO signaling is connected.
class SignalingStatusChip extends StatelessWidget {
  final bool compact;
  const SignalingStatusChip({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SignalingService().connectionNotifier,
      builder: (context, _) {
        final connected = SignalingService().isConnected;
        final color = connected ? const Color(0xFF059669) : const Color(0xFFDC2626);
        final label = connected ? 'Live' : 'Offline';
        return Tooltip(
          message: connected
              ? 'Signaling connected: ${AppConfig.signalingServerUrl}'
              : 'Signaling disconnected. Check Wi‑Fi IP or Cloud signaling URL.\n${AppConfig.signalingServerUrl}',
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 10,
              vertical: compact ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
