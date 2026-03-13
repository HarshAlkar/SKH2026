import 'dart:convert';
import 'package:http/http.dart' as http;
import '../connectivity/connectivity_service.dart';
import 'sync_queue_service.dart';

class SyncService {
  final ConnectivityService _connectivityService;
  final SyncQueueService _syncQueueService = SyncQueueService();
  bool _isSyncing = false;

  // A mock backend server string mapping
  final String _mockApiEndpoint = "https://api.graminhealthconnect.com/v1/sync";

  SyncService(this._connectivityService) {
    // Hook up local connectivity streaming explicitly checking on connection resets
    _connectivityService.connectionStatus.listen((isOnline) {
      if (isOnline) {
        _startBackgroundSync();
      }
    });
  }

  /// Triggers generic API pipeline if connectivity handles online responses
  Future<void> _startBackgroundSync() async {
    if (_isSyncing) return; // Prevent overlapping triggers
    _isSyncing = true;

    try {
      final pendingOperations = await _syncQueueService.getPendingOperations();

      if (pendingOperations.isEmpty) {
        _isSyncing = false;
        return;
      }

      print(
        'Found \${pendingOperations.length} pending operations. Starting sync...',
      );

      for (var op in pendingOperations) {
        bool success = await _pushToServer(op.operationType, op.payload);

        if (success) {
          await _syncQueueService.markOperationCompleted(op.id);
          print('Successfully synced operation: \${op.operationType}');
        } else {
          await _syncQueueService.markOperationFailed(op.id);
          print(
            'Failed to sync operation: \${op.operationType}. Marking for retry.',
          );
        }
      }
    } catch (e) {
      print('Sync failed due to unexpected error: \$e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Simulate backend push operations
  Future<bool> _pushToServer(String operationType, String payload) async {
    // In a real scenario:
    // final response = await http.post(
    //   Uri.parse(_mockApiEndpoint),
    //   body: jsonEncode({"type": operationType, "payload": jsonDecode(payload)}),
    // );
    // return response.statusCode == 200 || response.statusCode == 201;

    // Simulate network delay and 95% reliable backend response
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  /// External manual override logic
  Future<void> forceSync() async {
    if (_connectivityService.isOnline) {
      await _startBackgroundSync();
    }
  }
}
