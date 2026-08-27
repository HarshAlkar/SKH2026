import 'dart:async';

import 'package:flutter/foundation.dart';

import '../emergency_comms_config.dart';
import '../emergency_communication_service.dart';
import '../emergency_mode.dart';
import '../emergency_packet.dart';
import '../reliability/duplicate_filter.dart';
import '../reliability/emergency_queue.dart';
import '../transports/mock_lora_transport.dart';

/// In-process simulation. Logs the full hop path. Does not claim that a
/// LoRa radio transmitted anything.
class MockEmergencyService implements EmergencyCommunicationService {
  MockEmergencyService({
    EmergencyQueue? queue,
    DuplicateFilter? duplicates,
    MockLoRaTransport? transport,
  })  : _queue = queue ?? EmergencyQueue.instance,
        _duplicates = duplicates ?? DuplicateFilter(),
        _transport = transport ?? MockLoRaTransport();

  final EmergencyQueue _queue;
  final DuplicateFilter _duplicates;
  final MockLoRaTransport _transport;
  final StreamController<EmergencyPacket> _incoming =
      StreamController<EmergencyPacket>.broadcast();

  Timer? _flushTimer;

  @override
  EmergencyMode get mode => EmergencyMode.mock;

  @override
  Stream<EmergencyPacket> get incoming => _incoming.stream;

  @override
  bool get gatewayReachable => true;

  @override
  String get statusLabel => 'MOCK — simulation only, no radio';

  @override
  Future<void> initialize() async {
    debugPrint('EMERGENCY [init] mode=MOCK');
    await _transport.initialize();
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(
      EmergencyCommsConfig.retryBackoff,
      (_) => _flushQueue(),
    );
  }

  @override
  Future<void> dispose() async {
    _flushTimer?.cancel();
    await _transport.dispose();
    await _incoming.close();
  }

  @override
  Future<EmergencySendResult> send(EmergencyPacket packet) async {
    debugPrint('EMERGENCY [create] ${packet.encode()}');
    await _queue.enqueue(packet);
    debugPrint('EMERGENCY [queue] id=${packet.packetId} seq=${packet.seq} pri=${packet.priority}');
    final delivered = await _attempt(packet);
    if (delivered) {
      await _queue.markAcked(packet.packetId);
      return EmergencySendResult(
        queued: true,
        delivered: true,
        packetId: packet.packetId,
        message: 'Simulated (MOCK) — packet logged, no radio',
      );
    }
    return EmergencySendResult(
      queued: true,
      delivered: false,
      packetId: packet.packetId,
      message: 'Queued locally; mock hop did not complete',
    );
  }

  @override
  Future<void> acknowledge(EmergencyPacket packet) async {
    final ack = packet.ack();
    debugPrint('EMERGENCY [ack] ${ack.encode()} (MOCK, not sent over air)');
    await _queue.markAcked(packet.packetId);
  }

  @override
  Future<void> injectSimulatedIncoming(EmergencyPacket packet) async {
    debugPrint('EMERGENCY [sim-rx] ${packet.encode()}');
    if (await _duplicates.seen(packet.packetId)) {
      debugPrint('EMERGENCY [dup] drop ${packet.packetId}');
      return;
    }
    if (packet.isExpired) {
      debugPrint('EMERGENCY [ttl] drop ${packet.packetId}');
      return;
    }
    await _duplicates.mark(packet.packetId);
    _incoming.add(packet);
  }

  Future<bool> _attempt(EmergencyPacket packet) async {
    if (packet.isExpired) {
      debugPrint('EMERGENCY [ttl] expired ${packet.packetId}');
      await _queue.markRetry(packet.packetId, 'expired');
      return false;
    }
    debugPrint('EMERGENCY [sim-radio] TX ${packet.encode()}');
    final ok = await _transport.send(packet.encodeBytes());
    debugPrint('EMERGENCY [sim-radio] ${ok ? 'local ACK (not RF)' : 'fail'} id=${packet.packetId}');
    if (!ok) {
      await _queue.markRetry(packet.packetId, 'mock send failed');
    }
    return ok;
  }

  Future<void> _flushQueue() async {
    final pending = await _queue.pending();
    for (final packet in pending) {
      final delivered = await _attempt(packet);
      if (delivered) await _queue.markAcked(packet.packetId);
    }
  }
}
