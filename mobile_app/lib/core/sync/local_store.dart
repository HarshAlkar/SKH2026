import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalStore {
  static final LocalStore instance = LocalStore._();
  LocalStore._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'vitalreach.db'),
      version: 1,
      onCreate: (db, _) async {
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
      },
    );
    return _db!;
  }

  Future<int> enqueue({
    required String method,
    required String path,
    dynamic body,
  }) async {
    final db = await database;
    return db.insert('outbox', {
      'method': method.toUpperCase(),
      'path': path,
      'body': body == null ? null : jsonEncode(body),
      'status': 'pending',
      'retries': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> pending() async {
    final db = await database;
    return db.query(
      'outbox',
      where: "status = ?",
      whereArgs: ['pending'],
      orderBy: 'id ASC',
    );
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
  }

  Future<void> putCache(String key, dynamic payload) async {
    final db = await database;
    await db.insert(
      'cache_entries',
      {
        'cache_key': key,
        'payload': jsonEncode(payload),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
    return jsonDecode(rows.first['payload'] as String);
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
