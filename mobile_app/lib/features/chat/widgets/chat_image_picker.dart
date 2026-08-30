import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/services/permission_dialog_service.dart';

class ChatImagePicker {
  ChatImagePicker._();

  static Future<File?> pick(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return null;
    final permission =
        source == ImageSource.camera ? Permission.camera : Permission.photos;
    final allowed = await PermissionDialogService.ensure(
      context,
      permission: permission,
      title: 'Allow camera or photos',
      message:
          'Allow camera or gallery so you can send a photo in this chat for the doctor or ASHA to review.',
    );
    if (!allowed || !context.mounted) return null;
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked == null) return null;
    return File(picked.path);
  }
}

String chatPreviewText(Map<String, dynamic>? message) {
  if (message == null) return 'No messages';
  final text = message['text']?.toString() ?? '';
  final image = message['image_url']?.toString() ?? '';
  if (image.isNotEmpty && (text.isEmpty || text == '[Photo]')) return 'Photo';
  if (text == '[Photo]') return 'Photo';
  return text.isEmpty ? 'No messages' : text;
}
