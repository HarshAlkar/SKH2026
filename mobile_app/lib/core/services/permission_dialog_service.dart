import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionDialogService {
  PermissionDialogService._();

  static Future<bool> ensure(
    BuildContext context, {
    required Permission permission,
    required String title,
    required String message,
  }) async {
    final status = await permission.status;
    if (status.isGranted || status.isLimited) return true;

    if (!context.mounted) return false;
    if (status.isPermanentlyDenied || status.isRestricted) {
      return _openSettingsDialog(context, title: title, message: message);
    }

    final proceed = await _rationaleDialog(context, title: title, message: message);
    if (!proceed) return false;
    if (!context.mounted) return false;

    final result = await permission.request();
    if (result.isGranted || result.isLimited) return true;

    if (result.isPermanentlyDenied && context.mounted) {
      return _openSettingsDialog(context, title: title, message: message);
    }
    return false;
  }

  static Future<bool> ensureMany(
    BuildContext context, {
    required List<Permission> permissions,
    required String title,
    required String message,
  }) async {
    var allGranted = true;
    for (final permission in permissions) {
      final ok = await ensure(
        context,
        permission: permission,
        title: title,
        message: message,
      );
      if (!ok) allGranted = false;
      if (!context.mounted) return false;
    }
    return allGranted;
  }

  static Future<bool> ensureNotifications(BuildContext context) {
    return ensure(
      context,
      permission: Permission.notification,
      title: 'Allow notifications',
      message:
          'VitalReach needs notifications so you can be alerted for incoming calls, new messages, and medicine reminders.',
    );
  }

  static Future<bool> ensureCallPermissions(
    BuildContext context, {
    required bool isVideo,
  }) {
    final permissions = <Permission>[
      Permission.microphone,
      if (isVideo) Permission.camera,
    ];
    return ensureMany(
      context,
      permissions: permissions,
      title: isVideo ? 'Allow camera and microphone' : 'Allow microphone',
      message: isVideo
          ? 'Allow camera and microphone so you can start or answer a video call.'
          : 'Allow microphone so you can start or answer an audio call.',
    );
  }

  static Future<bool> ensureStorage(BuildContext context) async {
    final status = await Permission.storage.status;
    if (status.isGranted || status.isLimited) return true;
    if (!status.isDenied) return true;
    if (!context.mounted) return true;
    await ensure(
      context,
      permission: Permission.storage,
      title: 'Allow storage',
      message:
          'Allow storage so VitalReach can save chats, call records, and downloaded reports on this device.',
    );
    return true;
  }

  static Future<bool> _rationaleDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    return result == true;
  }

  static Future<bool> _openSettingsDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(
          '$message\n\nThis permission was previously denied. Open Settings to allow it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    if (result == true) {
      await openAppSettings();
    }
    return false;
  }
}
