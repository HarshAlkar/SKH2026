import 'emergency_queue.dart';

/// Drops retransmitted packets so retries do not stack UI or re-queue work.
class DuplicateFilter {
  DuplicateFilter({EmergencyQueue? queue}) : _queue = queue ?? EmergencyQueue.instance;

  final EmergencyQueue _queue;
  final Set<String> _memory = <String>{};
  static const int _memoryCap = 256;

  Future<bool> seen(String packetId) async {
    if (packetId.isEmpty) return false;
    if (_memory.contains(packetId)) return true;
    return _queue.hasSeen(packetId);
  }

  Future<void> mark(String packetId) async {
    if (packetId.isEmpty) return;
    _memory.add(packetId);
    if (_memory.length > _memoryCap) {
      _memory.remove(_memory.first);
    }
    await _queue.markSeen(packetId);
  }
}
