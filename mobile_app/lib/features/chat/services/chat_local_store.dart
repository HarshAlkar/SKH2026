import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/sync/local_store.dart';

class ChatLocalStore {
  ChatLocalStore._();
  static final ChatLocalStore instance = ChatLocalStore._();

  Future<Database> get _db => LocalStore.instance.database;

  Future<Map<String, dynamic>?> getThreadByPeer(int peerUserId) async {
    final rows = await (await _db).query(
      'chat_threads',
      where: 'peer_user_id = ?',
      whereArgs: [peerUserId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first);
  }

  Future<Map<String, dynamic>?> getThread(int id) async {
    final rows = await (await _db).query(
      'chat_threads',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first);
  }

  Future<List<Map<String, dynamic>>> listThreads({required bool hidden}) async {
    final rows = await (await _db).query(
      'chat_threads',
      where: 'hidden = ?',
      whereArgs: [hidden ? 1 : 0],
      orderBy: "COALESCE(last_at, updated_at) DESC",
    );
    return rows.map(_threadToApi).toList();
  }

  Map<String, dynamic> _threadToApi(Map<String, dynamic> row) {
    return {
      'id': row['id'],
      'peer_user_id': row['peer_user_id'],
      'peer_name': row['peer_name'] ?? 'Chat',
      'peer_phone': row['peer_phone'],
      'unread_count': row['unread'] ?? 0,
      'hidden': (row['hidden'] ?? 0) == 1,
      'updated_at': row['updated_at'] ?? row['last_at'],
      'last_message': row['last_text'] == null
          ? null
          : {
              'text': row['last_text'],
              'created_at': row['last_at'],
            },
    };
  }

  Future<void> upsertThread(
    Map<String, dynamic> thread, {
    bool? hidden,
    bool preserveHidden = true,
  }) async {
    final id = int.tryParse(thread['id']?.toString() ?? '');
    if (id == null) return;
    final db = await _db;
    final existing = await getThread(id);
    var hiddenValue = hidden == true ? 1 : 0;
    if (hidden == null && preserveHidden && existing != null) {
      hiddenValue = (existing['hidden'] as int?) ?? 0;
    } else if (hidden == null) {
      hiddenValue = existing?['hidden'] as int? ?? 0;
    }

    final last = thread['last_message'] is Map
        ? Map<String, dynamic>.from(thread['last_message'] as Map)
        : null;

    await db.insert(
      'chat_threads',
      {
        'id': id,
        'peer_user_id': int.tryParse(thread['peer_user_id']?.toString() ?? '') ?? 0,
        'peer_name': thread['peer_name']?.toString() ?? existing?['peer_name'] ?? 'Chat',
        'peer_phone': thread['peer_phone']?.toString() ?? existing?['peer_phone'],
        'last_text': last?['text']?.toString() ?? existing?['last_text'],
        'last_at': last?['created_at']?.toString() ??
            thread['updated_at']?.toString() ??
            existing?['last_at'],
        'unread': thread['unread_count'] ?? existing?['unread'] ?? 0,
        'hidden': hiddenValue,
        'updated_at': thread['updated_at']?.toString() ??
            DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> mergeRemoteThreads(List<Map<String, dynamic>> remote) async {
    for (final thread in remote) {
      await upsertThread(thread, preserveHidden: true);
    }
  }

  Future<void> setHidden(int threadId, bool hidden) async {
    final db = await _db;
    await db.update(
      'chat_threads',
      {'hidden': hidden ? 1 : 0},
      where: 'id = ?',
      whereArgs: [threadId],
    );
    await writeJsonBackup(threadId);
  }

  Future<void> upsertPendingMessage({
    required String clientId,
    required int threadId,
    int? senderId,
    required String text,
    required String createdAt,
  }) async {
    final db = await _db;
    await db.insert('chat_messages', {
      'client_id': clientId,
      'thread_id': threadId,
      'sender_id': senderId,
      'text': text,
      'created_at': createdAt,
      'pending_sync': 1,
    });
    final thread = await getThread(threadId);
    await db.insert(
      'chat_threads',
      {
        'id': threadId,
        'peer_user_id': thread?['peer_user_id'] ?? 0,
        'peer_name': thread?['peer_name'] ?? 'Chat',
        'peer_phone': thread?['peer_phone'],
        'last_text': text,
        'last_at': createdAt,
        'unread': thread?['unread'] ?? 0,
        'hidden': thread?['hidden'] ?? 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await writeJsonBackup(threadId);
  }

  Future<void> upsertMessage({
    int? serverId,
    required int threadId,
    int? senderId,
    required String text,
    String? createdAt,
    String? peerName,
    int? peerUserId,
  }) async {
    final db = await _db;
    if (serverId != null) {
      final existing = await db.query(
        'chat_messages',
        where: 'server_id = ?',
        whereArgs: [serverId],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        await db.update(
          'chat_messages',
          {
            'thread_id': threadId,
            'sender_id': senderId,
            'text': text,
            'created_at': createdAt ?? DateTime.now().toIso8601String(),
          },
          where: 'server_id = ?',
          whereArgs: [serverId],
        );
      } else {
        await db.insert('chat_messages', {
          'server_id': serverId,
          'thread_id': threadId,
          'sender_id': senderId,
          'text': text,
          'created_at': createdAt ?? DateTime.now().toIso8601String(),
        });
      }
    } else {
      await db.insert('chat_messages', {
        'thread_id': threadId,
        'sender_id': senderId,
        'text': text,
        'created_at': createdAt ?? DateTime.now().toIso8601String(),
      });
    }

    final thread = await getThread(threadId);
    await db.insert(
      'chat_threads',
      {
        'id': threadId,
        'peer_user_id': peerUserId ?? thread?['peer_user_id'] ?? 0,
        'peer_name': peerName ?? thread?['peer_name'] ?? 'Chat',
        'peer_phone': thread?['peer_phone'],
        'last_text': text,
        'last_at': createdAt ?? DateTime.now().toIso8601String(),
        'unread': thread?['unread'] ?? 0,
        'hidden': thread?['hidden'] ?? 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await writeJsonBackup(threadId);
  }

  Future<void> replaceMessages(int threadId, List<Map<String, dynamic>> messages) async {
    final db = await _db;
    await db.delete('chat_messages', where: 'thread_id = ?', whereArgs: [threadId]);
    for (final message in messages) {
      await upsertMessage(
        serverId: int.tryParse(message['id']?.toString() ?? ''),
        threadId: threadId,
        senderId: int.tryParse(message['sender_id']?.toString() ?? ''),
        text: message['text']?.toString() ?? '',
        createdAt: message['created_at']?.toString(),
      );
    }
    await writeJsonBackup(threadId);
  }

  Future<List<Map<String, dynamic>>> listMessages(int threadId) async {
    final rows = await (await _db).query(
      'chat_messages',
      where: 'thread_id = ?',
      whereArgs: [threadId],
      orderBy: 'COALESCE(created_at, id) ASC',
    );
    return rows
        .map(
          (row) => {
            'id': row['server_id'] ?? row['client_id'] ?? row['id'],
            'thread': threadId,
            'sender_id': row['sender_id'],
            'text': row['text'],
            'created_at': row['created_at'],
            'pending_sync': (row['pending_sync'] ?? 0) == 1,
          },
        )
        .toList();
  }

  Future<void> writeJsonBackup(int threadId) async {
    try {
      final thread = await getThread(threadId);
      if (thread == null) return;
      final messages = await listMessages(threadId);
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/chat_backup');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final file = File('${dir.path}/thread_$threadId.json');
      await file.writeAsString(
        jsonEncode({
          'thread': _threadToApi(thread),
          'messages': messages,
          'saved_at': DateTime.now().toIso8601String(),
        }),
      );
    } catch (_) {}
  }
}

class ChatSession {
  static int? openThreadId;
  static int? openPeerUserId;
}
