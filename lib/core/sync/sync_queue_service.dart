import '../database/database_service.dart';
import '../models/sync_operation_model.dart';

class SyncQueueService {
  final DatabaseService _dbService = DatabaseService();

  /// Enqueue an operation to be synced
  Future<void> addOperationToQueue(String type, String payload) async {
    final syncOp = SyncOperationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      operationType: type,
      payload: payload,
      status: 'pending',
      timestamp: DateTime.now().toIso8601String(),
    );

    await _dbService.insertData('sync_queue', syncOp.toJson());
  }

  /// Fetch all pending operations
  Future<List<SyncOperationModel>> getPendingOperations() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) {
      return SyncOperationModel.fromJson(maps[i]);
    });
  }

  /// Mark operation as completed and safe to drop
  Future<void> markOperationCompleted(String id) async {
    await _dbService.deleteData('sync_queue', id);
  }

  /// Mark operation as failed to retry later
  Future<void> markOperationFailed(String id) async {
    final db = await _dbService.database;
    await db.update(
      'sync_queue',
      {'status': 'failed'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
