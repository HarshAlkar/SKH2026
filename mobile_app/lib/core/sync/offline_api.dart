import '../services/api_service.dart';
import 'local_store.dart';
import 'sync_service.dart';

class OfflineWriteResult {
  final bool savedLocally;
  final bool synced;

  const OfflineWriteResult({
    required this.savedLocally,
    required this.synced,
  });

  String get message => synced
      ? 'Saved to cloud'
      : 'Saved on this phone. It will upload when internet is back.';
}

/// Reads from the cloud when possible, otherwise last cached copy.
/// Writes go to the phone first, then drain to Django when the network returns.
class OfflineApi {
  static final OfflineApi instance = OfflineApi._();
  OfflineApi._();

  final ApiService _api = ApiService();
  final LocalStore _store = LocalStore.instance;
  final SyncService _sync = SyncService.instance;

  Future<dynamic> get(String path) async {
    final cached = await _store.getCache(path);
    try {
      final data = await _api.get(
        path,
        timeout: cached != null
            ? const Duration(seconds: 8)
            : const Duration(seconds: 20),
      );
      await _store.putCache(path, data);
      return data;
    } catch (e) {
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<OfflineWriteResult> post(String path, {dynamic body}) {
    return _enqueue('POST', path, body);
  }

  Future<OfflineWriteResult> put(String path, {dynamic body}) {
    return _enqueue('PUT', path, body);
  }

  Future<OfflineWriteResult> patch(String path, {dynamic body}) {
    return _enqueue('PATCH', path, body);
  }

  Future<OfflineWriteResult> delete(String path) {
    return _enqueue('DELETE', path, null);
  }

  Future<OfflineWriteResult> postMultipart(
    String path, {
    required String filePath,
    String field = 'photo',
    Map<String, String>? fields,
    Map<String, dynamic>? body,
  }) {
    return _enqueue(
      'POST',
      path,
      body,
      filePath: filePath,
      fileField: field,
      fields: fields,
    );
  }

  Future<OfflineWriteResult> _enqueue(
    String method,
    String path,
    dynamic body, {
    String? filePath,
    String? fileField,
    Map<String, String>? fields,
  }) async {
    await _store.enqueue(
      method: method,
      path: path,
      body: body,
      filePath: filePath,
      fileField: fileField,
      fields: fields,
    );
    await _optimisticCache(method, path, body);
    await _sync.refreshPending();
    // Await flush so callers get accurate "Saved to cloud" vs "on this phone".
    await _sync.flush();
    final pending = await _store.pendingCount();
    return OfflineWriteResult(savedLocally: true, synced: pending == 0);
  }

  Future<void> _optimisticCache(
    String method,
    String path,
    dynamic body,
  ) async {
    if (method != 'POST' || body is! Map) return;
    final map = Map<String, dynamic>.from(body);
    final now = DateTime.now().toIso8601String();

    if (path.contains('/users/register')) {
      await _store.prependToListCache('/users/patients/', {
        'id': -DateTime.now().millisecondsSinceEpoch,
        'name': map['name'] ?? 'Patient',
        'phone_number': map['phone_number'] ?? '',
        'village': map['village'] ?? '',
        'profile_details': {
          'age': map['age'] ?? 0,
          'gender': map['gender'] ?? '',
          'blood_group': map['blood_group'] ?? '',
          'pending_sync': true,
        },
      });
    } else if (path.startsWith('/records/')) {
      await _store.prependToListCache('/records/', {
        'patientName': 'Saved on phone',
        'village': '',
        'temperature': map['temperature'] ?? '--',
        'bloodPressure': map['blood_pressure'] ?? '--',
        'bloodSugar': map['blood_sugar'] ?? '--',
        'weight': map['weight'] ?? '--',
        'lastUpdated': now,
        'riskLevel': 'normal',
      });
    } else if (path.startsWith('/asha/visits')) {
      await _store.prependToListCache('/asha/visits/', {
        'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
        'patient_name': 'Saved on phone',
        'village': '',
        'visit_date': map['visit_date'] ?? '',
        'visit_time': map['visit_time'] ?? '',
        'status': 'PENDING',
        'notes': map['notes'] ?? '',
      });
    } else if (path.contains('/stock/adjust')) {
      // Optimistic touch so list refresh feels immediate after offline adjust.
      final cached = await _store.getCache('/stock/batches/');
      if (cached is List && map['batch_id'] != null) {
        final batchId = map['batch_id'];
        final action = '${map['action'] ?? 'add'}';
        final qty = int.tryParse('${map['quantity'] ?? 0}') ?? 0;
        final updated = cached.map((row) {
          if (row is! Map) return row;
          if ('${row['id']}' != '$batchId') return row;
          final copy = Map<String, dynamic>.from(row);
          final current = int.tryParse('${copy['quantity'] ?? 0}') ?? 0;
          int next = current;
          if (action == 'add') {
            next = current + qty;
          } else if (action == 'adjust') {
            next = qty;
          } else {
            next = (current - qty).clamp(0, 1 << 30);
          }
          copy['quantity'] = next;
          copy['pending_sync'] = true;
          return copy;
        }).toList();
        await _store.putCache('/stock/batches/', updated);
      }
    }
  }
}
