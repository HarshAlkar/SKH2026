import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import 'local_store.dart';
import 'sync_status.dart';

class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  final ApiService _api = ApiService();
  final LocalStore _store = LocalStore.instance;
  final ConnectivityService _connectivity = ConnectivityService();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _flushing = false;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    SyncStatus.instance.setOnline(await _connectivity.isConnected());
    await refreshPending();
    _sub = _connectivity.connectivityStream.listen((results) {
      final online = ConnectivityService.isOnline(results);
      SyncStatus.instance.setOnline(online);
      if (online) {
        unawaited(flush());
      }
    });
    if (SyncStatus.instance.isOnline) {
      unawaited(flush());
    }
  }

  Future<void> refreshPending() async {
    SyncStatus.instance.setPending(await _store.pendingCount());
  }

  Future<bool> flush() async {
    if (_flushing) return false;
    if (!await _connectivity.isConnected()) {
      SyncStatus.instance.setOnline(false);
      await refreshPending();
      return false;
    }
    _flushing = true;
    SyncStatus.instance.setSyncing(true);
    String? lastError;
    try {
      final items = await _store.pending();
      for (final row in items) {
        final id = row['id'] as int;
        final method = (row['method'] as String).toUpperCase();
        final path = row['path'] as String;
        final rawBody = row['body'] as String?;
        final body = rawBody == null ? null : jsonDecode(rawBody);
        try {
          await _send(method, path, body);
          await _store.markSynced(id);
        } catch (e) {
          final message = e.toString();
          if (_alreadyOnServer(message)) {
            await _store.markSynced(id);
            continue;
          }
          lastError = message;
          debugPrint('Outbox retry $id $method $path: $e');
          await _store.markRetry(id, message);
          if (_isAuthError(message)) break;
        }
      }
    } finally {
      _flushing = false;
      SyncStatus.instance.setSyncing(false);
      SyncStatus.instance.setPending(
        await _store.pendingCount(),
        error: lastError,
      );
    }
    return (await _store.pendingCount()) == 0;
  }

  Future<void> _send(String method, String path, dynamic body) {
    const timeout = Duration(seconds: 25);
    switch (method) {
      case 'POST':
        return _api.post(path, body: body, timeout: timeout);
      case 'PUT':
        return _api.put(path, body: body, timeout: timeout);
      case 'PATCH':
        return _api.patch(path, body: body, timeout: timeout);
      case 'DELETE':
        return _api.delete(path);
      default:
        throw Exception('Unsupported sync method $method');
    }
  }

  bool _alreadyOnServer(String message) {
    final lower = message.toLowerCase();
    return lower.contains('already registered') ||
        lower.contains('already exists');
  }

  bool _isAuthError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('401') ||
        lower.contains('authentication') ||
        lower.contains('invalid token');
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _started = false;
  }
}
