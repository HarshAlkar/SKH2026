import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../security/secure_payload_crypto.dart';
import 'blackout_recovery.dart';
import 'shadow_store.dart';

class LocalStore {
  static final LocalStore instance = LocalStore._();
  LocalStore._();

  Database? _db;
  final _crypto = SecurePayloadCrypto.instance;
  final _shadow = ShadowStore.instance;
  bool _opening = false;

  Future<Database> get database async {
    if (_db != null) {
      if (await _isHealthy(_db!)) return _db!;
      await _closeAndDropPrimary();
      return _openWithRecovery();
    }
    return _openWithRecovery();
  }

  Future<Database> _openWithRecovery() async {
    if (_opening) {
      while (_opening) {
        await Future<void>.delayed(const Duration(milliseconds: 30));
      }
      if (_db != null) return _db!;
    }
    _opening = true;
    try {
      final path = await BlackoutRecovery.primaryDbPath();
      final exists = await File(path).exists();
      if (exists) {
        try {
          final db = await _openPrimary(path);
          if (await _isHealthy(db)) {
            _db = db;
            return _db!;
          }
          await db.close();
          await deleteDatabase(path);
        } catch (e) {
          debugPrint('LocalStore: primary open failed: $e');
          try {
            await deleteDatabase(path);
          } catch (_) {}
        }
      }

      // Missing or corrupt primary: rebuild from shadow when it has data.
      final shadowOutbox = await _shadow.allOutbox();
      final shadowCache = await _shadow.allCache();
      if (shadowOutbox.isNotEmpty || shadowCache.isNotEmpty) {
        // Avoid nested open while recovering.
        _opening = false;
        await BlackoutRecovery.instance.recoverAfterCorruption();
        if (_db != null) return _db!;
        _opening = true;
      }

      _db = await _openPrimary(path);
      return _db!;
    } finally {
      _opening = false;
    }
  }

  Future<Database> _openPrimary(String path) {
    return openDatabase(
      path,
      version: 4,
      onCreate: (db, _) async {
        await _createV1Tables(db);
        await _createChatTables(db);
        await _upgradeToV3(db);
        await _upgradeToV4(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createChatTables(db);
        }
        if (oldVersion < 3) {
          await _upgradeToV3(db);
        }
        if (oldVersion < 4) {
          await _upgradeToV4(db);
        }
      },
    );
  }

  Future<bool> _isHealthy(Database db) async {
    try {
      final check = await db.rawQuery('PRAGMA integrity_check');
      final ok = check.isNotEmpty && '${check.first.values.first}' == 'ok';
      if (!ok) return false;
      await db.rawQuery('SELECT COUNT(*) FROM outbox');
      await db.rawQuery('SELECT COUNT(*) FROM cache_entries');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _closeAndDropPrimary() async {
    try {
      await _db?.close();
    } catch (_) {}
    _db = null;
    try {
      await deleteDatabase(await BlackoutRecovery.primaryDbPath());
    } catch (e) {
      debugPrint('LocalStore: delete primary failed: $e');
    }
  }

  /// Demo / recovery: close and delete vitalreach.db (shadow untouched).
  Future<void> destroyPrimaryDatabase() async {
    await _closeAndDropPrimary();
  }

  /// Create a fresh primary schema and keep the handle open (for restore).
  Future<Database> recreateEmptyPrimary() async {
    await _closeAndDropPrimary();
    final path = await BlackoutRecovery.primaryDbPath();
    _db = await _openPrimary(path);
    return _db!;
  }

  Future<void> _createV1Tables(Database db) async {
    await db.execute('''
      CREATE TABLE outbox (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        method TEXT NOT NULL,
        path TEXT NOT NULL,
        body TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        retries INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE cache_entries (
        cache_key TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createChatTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_threads (
        id INTEGER PRIMARY KEY,
        peer_user_id INTEGER NOT NULL,
        peer_name TEXT,
        peer_phone TEXT,
        last_text TEXT,
        last_at TEXT,
        unread INTEGER NOT NULL DEFAULT 0,
        hidden INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        thread_id INTEGER NOT NULL,
        sender_id INTEGER,
        text TEXT NOT NULL,
        created_at TEXT
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_chat_messages_server_id ON chat_messages(server_id) WHERE server_id IS NOT NULL',
    );
  }

  Future<void> _upgradeToV3(Database db) async {
    await db.execute('ALTER TABLE outbox ADD COLUMN file_path TEXT');
    await db.execute('ALTER TABLE outbox ADD COLUMN file_field TEXT');
    await db.execute('ALTER TABLE outbox ADD COLUMN fields_json TEXT');
    await db.execute('ALTER TABLE chat_messages ADD COLUMN pending_sync INTEGER NOT NULL DEFAULT 0');
    await db.execute('ALTER TABLE chat_messages ADD COLUMN client_id TEXT');
  }

  Future<void> _upgradeToV4(Database db) async {
    try {
      await db.execute('ALTER TABLE chat_messages ADD COLUMN image_url TEXT');
    } catch (_) {}
  }

  Future<int> enqueue({
    required String method,
    required String path,
    dynamic body,
    String? filePath,
    String? fileField,
    Map<String, String>? fields,
  }) async {
    final db = await database;
    dynamic enriched = body;
    if (body is Map && body['client_id'] == null) {
      enriched = Map<String, dynamic>.from(body)
        ..['client_id'] =
            '${DateTime.now().microsecondsSinceEpoch}-${method.hashCode.abs()}';
    }
    final encryptedBody = await _crypto.encryptJson(enriched);
    final createdAt = DateTime.now().toIso8601String();
    final id = await db.insert('outbox', {
      'method': method.toUpperCase(),
      'path': path,
      'body': encryptedBody,
      'file_path': filePath,
      'file_field': fileField,
      'fields_json': fields == null ? null : jsonEncode(fields),
      'status': 'pending',
      'retries': 0,
      'created_at': createdAt,
    });
    try {
      await _shadow.upsertOutbox({
        'id': id,
        'method': method.toUpperCase(),
        'path': path,
        'body': encryptedBody,
        'file_path': filePath,
        'file_field': fileField,
        'fields_json': fields == null ? null : jsonEncode(fields),
        'status': 'pending',
        'retries': 0,
        'last_error': null,
        'created_at': createdAt,
      });
    } catch (e) {
      debugPrint('ShadowStore outbox mirror failed: $e');
    }
    return id;
  }

  Future<void> deleteOutboxRow(int id) async {
    final db = await database;
    await db.delete('outbox', where: 'id = ?', whereArgs: [id]);
    try {
      await _shadow.deleteOutbox(id);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> pending() async {
    final db = await database;
    final rows = await db.query(
      'outbox',
      where: "status = ?",
      whereArgs: ['pending'],
      orderBy: 'id ASC',
    );
    final out = <Map<String, dynamic>>[];
    for (final row in rows) {
      final copy = Map<String, dynamic>.from(row);
      final rawBody = copy['body'] as String?;
      if (rawBody != null && rawBody.isNotEmpty) {
        try {
          copy['body'] = jsonEncode(await _crypto.decryptJson(rawBody));
        } catch (_) {}
      }
      out.add(copy);
    }
    return out;
  }

  Future<int> pendingCount() async {
    final db = await database;
    final rows = await db.rawQuery(
      "SELECT COUNT(*) AS c FROM outbox WHERE status = 'pending'",
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<void> markSynced(int id) async {
    final db = await database;
    await db.update(
      'outbox',
      {'status': 'synced', 'last_error': null},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _mirrorOutboxStatus(id);
  }

  Future<void> markRetry(int id, String error) async {
    final db = await database;
    final rows = await db.query('outbox', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return;
    final retries = (rows.first['retries'] as int? ?? 0) + 1;
    await db.update(
      'outbox',
      {
        'retries': retries,
        'last_error': error,
        'status': retries >= 12 ? 'failed' : 'pending',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await _mirrorOutboxStatus(id);
  }

  Future<void> _mirrorOutboxStatus(int id) async {
    try {
      final db = await database;
      final rows = await db.query('outbox', where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) {
        await _shadow.deleteOutbox(id);
        return;
      }
      await _shadow.upsertOutbox(Map<String, dynamic>.from(rows.first));
    } catch (e) {
      debugPrint('ShadowStore status mirror failed: $e');
    }
  }

  Future<void> putCache(String key, dynamic payload) async {
    final db = await database;
    final encrypted = await _crypto.encryptJson(payload);
    final updatedAt = DateTime.now().toIso8601String();
    await db.insert(
      'cache_entries',
      {
        'cache_key': key,
        'payload': encrypted ?? '',
        'updated_at': updatedAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    try {
      await _shadow.upsertCache(
        cacheKey: key,
        payload: encrypted ?? '',
        updatedAt: updatedAt,
      );
    } catch (e) {
      debugPrint('ShadowStore cache mirror failed: $e');
    }
  }

  Future<dynamic> getCache(String key) async {
    final db = await database;
    final rows = await db.query(
      'cache_entries',
      where: 'cache_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _crypto.decryptJson(rows.first['payload'] as String);
  }

  Future<void> prependToListCache(String key, Map<String, dynamic> item) async {
    final existing = await getCache(key);
    final list = existing is List
        ? existing.map((e) => e is Map ? Map<String, dynamic>.from(e) : e).toList()
        : <dynamic>[];
    list.insert(0, item);
    await putCache(key, list);
  }
}
