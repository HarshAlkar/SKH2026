import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'permission_dialog_service.dart';

class FileSaveService {
  FileSaveService._();

  static Future<String> saveBytes({
    required Uint8List bytes,
    required String filename,
    BuildContext? context,
  }) async {
    final docs = await getApplicationDocumentsDirectory();
    final innerDir = Directory('${docs.path}/downloads');
    if (!await innerDir.exists()) {
      await innerDir.create(recursive: true);
    }
    final innerFile = File('${innerDir.path}/$filename');
    await innerFile.writeAsBytes(bytes, flush: true);
    var savedPath = innerFile.path;

    if (context != null && context.mounted) {
      await PermissionDialogService.ensureStorage(context);
    }

    try {
      Directory? downloads;
      if (Platform.isAndroid) {
        downloads = Directory('/storage/emulated/0/Download');
      } else {
        downloads = await getDownloadsDirectory();
      }
      if (downloads != null && await downloads.exists()) {
        final publicFile = File('${downloads.path}/$filename');
        await publicFile.writeAsBytes(bytes, flush: true);
        savedPath = publicFile.path;
      }
    } catch (_) {}

    return savedPath;
  }
}
