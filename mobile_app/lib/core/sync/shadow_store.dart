import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Secondary mirror of outbox + cache. Survives wipe of [vitalreach.db].
class ShadowStore {
  static final ShadowStore instance = ShadowStore._();
  ShadowStore._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'vitalreach_shadow.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE outbox (
            id INTEGER PRIMARY KEY,
            method TEXT NOT NULL,
            path TEXT NOT NULL,
            body TEXT,
            status TEXT NOT NULL DEFAULT 'pending',
            retries INTEGER NOT NULL DEFAULT 0,
            last_error TEXT,
            created_at TEXT NOT NULL,
            file_path TEXT,
            file_field TEXT,
            fields_json TEXT
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

  Future<void> upsertOutbox(Map<String, dynamic> row) async {
    final db = await database;
    await db.insert(
      'outbox',
      {
        'id': row['id'],
        'method': row['method'],
        'path': row['path'],
        'body': row['body'],
        'status': row['status'] ?? 'pending',
        'retries': row['retries'] ?? 0,
        'last_error': row['last_error'],
        'created_at': row['created_at'],
        'file_path': row['file_path'],
        'file_field': row['file_field'],
        'fields_json': row['fields_json'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteOutbox(int id) async {
    final db = await database;
    await db.delete('outbox', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> upsertCache({
    required String cacheKey,
    required String payload,
    required String updatedAt,
  }) async {
    final db = await database;
    await db.insert(
      'cache_entries',
      {
        'cache_key': cacheKey,
        'payload': payload,
        'updated_at': updatedAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> allOutbox() async {
    final db = await database;
    return db.query('outbox', orderBy: 'id ASC');
  }

  Future<List<Map<String, dynamic>>> allCache() async {
    final db = await database;
    return db.query('cache_entries');
  }

  Future<int> pendingCount() async {
    final db = await database;
    final rows = await db.rawQuery(
      "SELECT COUNT(*) AS c FROM outbox WHERE status = 'pending'",
    );
    return (rows.first['c'] as int?) ?? 0;
  }
}
