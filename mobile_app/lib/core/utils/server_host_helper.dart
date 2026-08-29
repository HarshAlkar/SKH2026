import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../../providers/auth_provider.dart';
import 'logout_helper.dart';

class ServerHostHelper {
  ServerHostHelper._();

  static String _normalize(String value) {
    return value.trim().replaceAll(RegExp(r'/+$'), '').toLowerCase();
  }

  static Future<void> saveHost(
    BuildContext context,
    String value, {
    String? savedMessage,
  }) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    final oldHost = AppConfig.host;
    final hostChanged = _normalize(oldHost) != _normalize(trimmed);

    await AppConfig.setHost(trimmed);
    // Always derive signaling from the API host (ignore any old manual override).
    await AppConfig.clearSignalingUrl();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          savedMessage ??
              'Server saved. API: ${AppConfig.baseUrl} · Calls: ${AppConfig.signalingServerUrl}',
        ),
      ),
    );

    if (!hostChanged || !context.mounted) return;

    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Server changed'),
        content: const Text(
          'The server host was updated. You must log in again to use the new server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    await LogoutHelper.logout(context);
  }
}
