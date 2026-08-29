import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'local_store.dart';
import 'shadow_store.dart';
import 'sync_service.dart';
import 'sync_status.dart';

/// Detects primary datastore wipe/corruption and rebuilds from [ShadowStore].
///
/// Live demo script (≈90s):
/// 1. Save a screening (outbox + shadow dual-write).
/// 2. Tap Simulate Blackout — wipes vitalreach.db only.
/// 3. Banner: Blackout detected → Recovered N items from shadow.
/// 4. Data still on phone; SyncService flushes when online.
class BlackoutRecovery {
  static final BlackoutRecovery instance = BlackoutRecovery._();
  BlackoutRecovery._();

  bool _recovering = false;

  /// Opens primary (restoring from shadow if needed) and refreshes pending count.
  Future<void> ensureHealthy() async {
    await LocalStore.instance.database;
    await SyncService.instance.refreshPending();
  }

  /// Judge demo: destroy primary DB file while the app is running.
  Future<BlackoutResult> simulateBlackout() async {
    SyncStatus.instance.setBlackout(
      phase: BlackoutPhase.detecting,
      message: 'Blackout detected — primary datastore wiped…',
    );

    await LocalStore.instance.destroyPrimaryDatabase();

    SyncStatus.instance.setBlackout(
      phase: BlackoutPhase.restoring,
      message: 'Blackout detected — restoring local records…',
    );

    final result = await restoreFromShadow();
    await SyncService.instance.refreshPending();

    if (result.recoveredOutbox > 0 || result.recoveredCache > 0) {
      SyncStatus.instance.setBlackout(
        phase: BlackoutPhase.recovered,
        recoveredCount: result.recoveredOutbox,
        message: result.lostInFlight
            ? 'Recovered ${result.recoveredOutbox} item(s); 1 in-flight write may be lost'
            : 'Recovered ${result.recoveredOutbox} pending item(s) from shadow store',
      );
    } else {
      SyncStatus.instance.setBlackout(
        phase: BlackoutPhase.recovered,
        recoveredCount: 0,
        message: 'Primary store rebuilt — no shadow rows to restore',
      );
    }

    // Keep recovered banner visible for the live demo, then clear phase.
    Future<void>.delayed(const Duration(seconds: 12), () {
      if (SyncStatus.instance.blackoutPhase == BlackoutPhase.recovered) {
        SyncStatus.instance.clearBlackout();
      }
    });

    return result;
  }

  /// Rebuild primary outbox/cache from shadow after wipe or corruption.
  Future<BlackoutResult> restoreFromShadow() async {
    if (_recovering) {
      return const BlackoutResult(recoveredOutbox: 0, recoveredCache: 0);
    }
    _recovering = true;
    try {
      final shadow = ShadowStore.instance;
      final outboxRows = await shadow.allOutbox();
      final cacheRows = await shadow.allCache();

      // Force a fresh primary DB (create empty schema).
      final db = await LocalStore.instance.recreateEmptyPrimary();

      var outboxCount = 0;
      for (final row in outboxRows) {
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
        if ((row['status'] as String?) == 'pending') outboxCount++;
      }

      var cacheCount = 0;
      for (final row in cacheRows) {
        await db.insert(
          'cache_entries',
          {
            'cache_key': row['cache_key'],
            'payload': row['payload'],
            'updated_at': row['updated_at'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        cacheCount++;
      }

      debugPrint(
        'BlackoutRecovery: restored $outboxCount pending outbox, '
        '$cacheCount cache entries from shadow',
      );

      return BlackoutResult(
        recoveredOutbox: outboxCount,
        recoveredCache: cacheCount,
      );
    } finally {
      _recovering = false;
    }
  }

  /// Called when primary open/integrity fails.
  Future<BlackoutResult> recoverAfterCorruption() async {
    SyncStatus.instance.setBlackout(
      phase: BlackoutPhase.detecting,
      message: 'Blackout detected — primary datastore unreadable…',
    );
    SyncStatus.instance.setBlackout(
      phase: BlackoutPhase.restoring,
      message: 'Blackout detected — restoring local records…',
    );

    final result = await restoreFromShadow();
    await SyncService.instance.refreshPending();

    SyncStatus.instance.setBlackout(
      phase: BlackoutPhase.recovered,
      recoveredCount: result.recoveredOutbox,
      message: result.recoveredOutbox > 0
          ? 'Recovered ${result.recoveredOutbox} pending item(s) from shadow store'
          : 'Primary store rebuilt from shadow',
    );

    Future<void>.delayed(const Duration(seconds: 12), () {
      if (SyncStatus.instance.blackoutPhase == BlackoutPhase.recovered) {
        SyncStatus.instance.clearBlackout();
      }
    });

    return result;
  }

  static Future<String> primaryDbPath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'vitalreach.db');
  }

  static Future<bool> primaryFileExists() async {
    return File(await primaryDbPath()).exists();
  }
}

class BlackoutResult {
  final int recoveredOutbox;
  final int recoveredCache;
  final bool lostInFlight;

  const BlackoutResult({
    required this.recoveredOutbox,
    required this.recoveredCache,
    this.lostInFlight = false,
  });
}
