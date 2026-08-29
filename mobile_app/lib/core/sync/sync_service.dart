import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import '../services/storage_service.dart';
import '../security/secure_session_store.dart';
import 'local_store.dart';
import 'pending_upload_store.dart';
import 'sync_status.dart';

class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  final ApiService _api = ApiService();
  final LocalStore _store = LocalStore.instance;
  final ConnectivityService _connectivity = ConnectivityService();
  final StorageService _storage = StorageService();
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
        final filePath = row['file_path'] as String?;
        final fileField = row['file_field'] as String?;
        final fieldsRaw = row['fields_json'] as String?;
        final fields = fieldsRaw == null
            ? null
            : Map<String, String>.from(jsonDecode(fieldsRaw) as Map);
        try {
          final response = await _send(
            method,
            path,
            body,
            filePath: filePath,
            fileField: fileField,
            fields: fields,
          );
          await _afterSync(path, body, response, filePath: filePath);
          await _store.markSynced(id);
          if (filePath != null) {
            await PendingUploadStore.instance.deleteIfExists(filePath);
          }
        } catch (e) {
          final message = e.toString();
          if (_alreadyOnServer(message)) {
            await _store.markSynced(id);
            if (filePath != null) {
              await PendingUploadStore.instance.deleteIfExists(filePath);
            }
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

  Future<dynamic> _send(
    String method,
    String path,
    dynamic body, {
    String? filePath,
    String? fileField,
    Map<String, String>? fields,
  }) {
    const timeout = Duration(seconds: 25);
    if (filePath != null && filePath.isNotEmpty && method == 'POST') {
      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('Pending upload file missing: $filePath');
      }
      return _api.postMultipart(
        path,
        file: file,
        field: fileField ?? 'photo',
        fields: fields,
        timeout: timeout,
      );
    }
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

  Future<void> _afterSync(
    String path,
    dynamic body,
    dynamic response, {
    String? filePath,
  }) async {
    if (path.contains('/chat/threads/') && path.endsWith('/messages/')) {
      await _resolveChatMessage(body, response);
    } else if (path == '/users/me/photo/' && response is Map) {
      await _resolveProfilePhoto(response, filePath: filePath);
    }
  }

  Future<void> _resolveChatMessage(dynamic body, dynamic response) async {
    if (body is! Map || response is! Map) return;
    final clientId = body['client_message_id']?.toString();
    if (clientId == null || clientId.isEmpty) return;
    final threadId = int.tryParse(body['thread_id']?.toString() ?? '');
    final serverId = int.tryParse(response['id']?.toString() ?? '');
    if (threadId == null || serverId == null) return;

    final db = await _store.database;
    await db.update(
      'chat_messages',
      {
        'server_id': serverId,
        'pending_sync': 0,
        'created_at': response['created_at']?.toString() ??
            DateTime.now().toIso8601String(),
      },
      where: 'client_id = ? AND thread_id = ?',
      whereArgs: [clientId, threadId],
    );
  }

  Future<void> _resolveProfilePhoto(Map response, {String? filePath}) async {
    final session = SecureSessionStore.instance;
    final raw = await session.readUserDataJson();
    if (raw == null) return;
    final user = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    if (response['photo_url'] != null) {
      user['photo_url'] = response['photo_url'];
    } else if (response['user'] is Map) {
      final nested = Map<String, dynamic>.from(response['user'] as Map);
      if (nested['photo_url'] != null) {
        user['photo_url'] = nested['photo_url'];
      }
    }
    user.remove('pending_photo_path');
    final token = await session.readToken() ?? '';
    await session.writeSession(token: token, userDataJson: jsonEncode(user));
    if (filePath != null) {
      await PendingUploadStore.instance.deleteIfExists(filePath);
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
