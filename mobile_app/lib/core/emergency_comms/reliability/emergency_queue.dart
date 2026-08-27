import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../emergency_comms_config.dart';
import '../emergency_packet.dart';

/// Persistent high-priority send queue. Separate from the Django REST outbox
/// in [LocalStore] so offline radio traffic never depends on cloud sync.
class EmergencyQueue {
  EmergencyQueue._();
  static final EmergencyQueue instance = EmergencyQueue._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dir, 'vitalreach_emergency.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE emergency_outbox (
            packet_id TEXT PRIMARY KEY,
            seq INTEGER NOT NULL,
            payload TEXT NOT NULL,
            priority INTEGER NOT NULL,
            ttl INTEGER NOT NULL,
            retries INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL,
            last_error TEXT,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE emergency_seen (
            packet_id TEXT PRIMARY KEY,
            seen_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE emergency_meta (
            key TEXT PRIMARY KEY,
            value INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<int> nextSequence() async {
    final db = await database;
    final rows = await db.query(
      'emergency_meta',
      where: 'key = ?',
      whereArgs: ['seq'],
      limit: 1,
    );
    final current = rows.isEmpty ? 0 : (rows.first['value'] as int? ?? 0);
    final next = current + 1;
    await db.insert(
      'emergency_meta',
      {'key': 'seq', 'value': next},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return next;
  }

  Future<void> enqueue(EmergencyPacket packet) async {
    final db = await database;
    await db.insert(
      'emergency_outbox',
      {
        'packet_id': packet.packetId,
        'seq': packet.seq,
        'payload': packet.encode(),
        'priority': packet.priority,
        'ttl': packet.ttl,
        'retries': 0,
        'status': 'pending',
        'created_at': packet.timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<EmergencyPacket>> pending() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await db.update(
      'emergency_outbox',
      {'status': 'expired'},
      where: "status = 'pending' AND ttl <= ?",
      whereArgs: [now],
    );
    final rows = await db.query(
      'emergency_outbox',
      where: "status = 'pending'",
      orderBy: 'priority DESC, seq ASC',
    );
    return rows
        .map((row) => EmergencyPacket.decode(row['payload'] as String))
        .toList();
  }

  Future<int> pendingCount() async {
    final db = await database;
    final rows = await db.rawQuery(
      "SELECT COUNT(*) AS c FROM emergency_outbox WHERE status = 'pending'",
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<void> markAcked(String packetId) async {
    final db = await database;
    await db.update(
      'emergency_outbox',
      {'status': 'acked', 'last_error': null},
      where: 'packet_id = ?',
      whereArgs: [packetId],
    );
  }

  Future<void> markRetry(String packetId, String error) async {
    final db = await database;
    final rows = await db.query(
      'emergency_outbox',
      where: 'packet_id = ?',
      whereArgs: [packetId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final retries = (rows.first['retries'] as int? ?? 0) + 1;
    final expired = retries >= EmergencyCommsConfig.maxRetries;
    await db.update(
      'emergency_outbox',
      {
        'retries': retries,
        'last_error': error,
        'status': expired ? 'failed' : 'pending',
      },
      where: 'packet_id = ?',
      whereArgs: [packetId],
    );
  }

  Future<bool> hasSeen(String packetId) async {
    final db = await database;
    final rows = await db.query(
      'emergency_seen',
      where: 'packet_id = ?',
      whereArgs: [packetId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> markSeen(String packetId) async {
    final db = await database;
    await db.insert(
      'emergency_seen',
      {
        'packet_id': packetId,
        'seen_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
}
