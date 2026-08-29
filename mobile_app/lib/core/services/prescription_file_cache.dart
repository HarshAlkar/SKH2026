import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// App-private cache for previously downloaded prescription files (offline view).
class PrescriptionFileCache {
  PrescriptionFileCache._();
  static final PrescriptionFileCache instance = PrescriptionFileCache._();

  Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'rx_cache'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File?> find(int prescriptionId, {String? contentType}) async {
    final dir = await _dir();
    final ext = _extFor(contentType);
    final file = File(p.join(dir.path, 'rx_$prescriptionId$ext'));
    if (await file.exists()) return file;
    // Fallback: any extension for this id
    await for (final entity in dir.list()) {
      if (entity is File && p.basename(entity.path).startsWith('rx_$prescriptionId.')) {
        return entity;
      }
    }
    return null;
  }

  Future<File> save(int prescriptionId, List<int> bytes, {String? contentType}) async {
    final dir = await _dir();
    final ext = _extFor(contentType);
    final file = File(p.join(dir.path, 'rx_$prescriptionId$ext'));
    await file.writeAsBytes(Uint8List.fromList(bytes), flush: true);
    return file;
  }

  String _extFor(String? contentType) {
    final ct = (contentType ?? '').toLowerCase();
    if (ct.contains('pdf')) return '.pdf';
    if (ct.contains('png')) return '.png';
    if (ct.contains('webp')) return '.webp';
    if (ct.contains('gif')) return '.gif';
    return '.jpg';
  }
}
