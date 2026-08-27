import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Persists files referenced by the sync outbox until upload completes.
class PendingUploadStore {
  PendingUploadStore._();
  static final PendingUploadStore instance = PendingUploadStore._();

  Future<File> saveProfilePhoto(File source) async {
    final dir = await _uploadDir();
    final name = 'profile_${DateTime.now().millisecondsSinceEpoch}${p.extension(source.path)}';
    final dest = File(p.join(dir.path, name));
    await dest.writeAsBytes(await source.readAsBytes(), flush: true);
    return dest;
  }

  Future<void> deleteIfExists(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<Directory> _uploadDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'pending_uploads'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
