import 'dart:async';

import 'package:flutter/foundation.dart';

import '../emergency_comms_config.dart';
import '../emergency_communication_service.dart';
import '../emergency_mode.dart';
import '../emergency_packet.dart';
import '../lora_transport.dart';
import '../reliability/duplicate_filter.dart';
import '../reliability/emergency_queue.dart';
import '../transports/esp32_http_client.dart';
import '../transports/mock_lora_transport.dart';

/// Phone still talks HTTP to the ESP32. The `fwd=lora` flag tells firmware
/// to call [LoRaTransport.send] on the gateway. Until a radio is wired,
/// firmware MOCK / Dart mock must not report RF success.
class LoRaEmergencyService implements EmergencyCommunicationService {
  LoRaEmergencyService({
    EmergencyQueue? queue,
    DuplicateFilter? duplicates,
    Esp32HttpClient? client,
    LoRaTransport? transport,
  })  : _queue = queue ?? EmergencyQueue.instance,
        _duplicates = duplicates ?? DuplicateFilter(),
        _client = client ?? Esp32HttpClient(),
        _transport = transport ?? MockLoRaTransport();

  final EmergencyQueue _queue;
  final DuplicateFilter _duplicates;
  final Esp32HttpClient _client;
  final LoRaTransport _transport;
  final StreamController<EmergencyPacket> _incoming =
      StreamController<EmergencyPacket>.broadcast();

  Timer? _pollTimer;
  Timer? _flushTimer;
  bool _reachable = false;

  @override
  EmergencyMode get mode => EmergencyMode.lora;

  @override
  Stream<EmergencyPacket> get incoming => _incoming.stream;

  @override
  bool get gatewayReachable => _reachable;

  @override
  String get statusLabel {
    if (!_reachable) return 'LORA — gateway unreachable / radio not connected';
    final signal = _transport.getSignalStatus();
    if (!signal.linked) {
      return 'LORA — ESP32 up, radio not connected';
    }
    return 'LORA — radio linked rssi=${signal.rssi ?? '-'}';
  }

  @override
  Future<void> initialize() async {
    debugPrint('EMERGENCY [init] mode=LORA gateway=${EmergencyCommsConfig.gatewayOrigin}');
    // TODO(hardware): replace MockLoRaTransport with a native/serial driver
    // once the ESP32 LoRa module is wired. Phones do not speak LoRa directly.
    await _transport.initialize();
    _reachable = await _client.health();
    debugPrint('EMERGENCY [esp32] health=${_reachable ? 'ok' : 'down'} radio=${_transport.isConnected}');
    _pollTimer?.cancel();
    _flushTimer?.cancel();
    _pollTimer = Timer.periodic(EmergencyCommsConfig.inboxPollInterval, (_) => _pollInbox());
    _flushTimer = Timer.periodic(EmergencyCommsConfig.retryBackoff, (_) => _flushQueue());
  }

  @override
  Future<void> dispose() async {
    _pollTimer?.cancel();
    _flushTimer?.cancel();
    await _transport.dispose();
    _client.close();
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
        message: 'ESP32 accepted packet for LoRa TX',
      );
    }
    return EmergencySendResult(
      queued: true,
      delivered: false,
      packetId: packet.packetId,
      message: 'Queued — gateway unreachable / radio not connected',
    );
  }

  @override
  Future<void> acknowledge(EmergencyPacket packet) async {
    final ack = packet.ack();
    debugPrint('EMERGENCY [ack] ${ack.encode()}');
    await _client.postAck(ack);
    await _queue.markAcked(packet.packetId);
  }

  @override
  Future<void> injectSimulatedIncoming(EmergencyPacket packet) async {
    debugPrint('EMERGENCY [sim-rx] ${packet.encode()}');
    await _emitIncoming(packet);
  }

  Future<bool> _attempt(EmergencyPacket packet) async {
    if (packet.isExpired) {
      await _queue.markRetry(packet.packetId, 'expired');
      return false;
    }
    debugPrint('EMERGENCY [lora] TX → ESP32 fwd=lora ${packet.encode()}');
    final ok = await _client.postEmergency(packet, forwardLora: true);
    _reachable = ok || await _client.health();
    if (!ok) {
      await _queue.markRetry(packet.packetId, 'gateway unreachable');
      debugPrint('EMERGENCY [lora] no ACK — leaving in queue (not claiming RF success)');
    } else {
      debugPrint('EMERGENCY [lora] ESP32 ACK id=${packet.packetId} (radio TX is firmware-side)');
    }
    return ok;
  }

  Future<void> _flushQueue() async {
    for (final packet in await _queue.pending()) {
      final delivered = await _attempt(packet);
      if (delivered) await _queue.markAcked(packet.packetId);
    }
  }

  Future<void> _pollInbox() async {
    final packets = await _client.fetchInbox();
    _reachable = packets.isNotEmpty || await _client.health();
    for (final packet in packets) {
      await _emitIncoming(packet);
    }
  }

  Future<void> _emitIncoming(EmergencyPacket packet) async {
    if (await _duplicates.seen(packet.packetId)) {
      debugPrint('EMERGENCY [dup] drop ${packet.packetId}');
      return;
    }
    if (packet.isExpired) {
      debugPrint('EMERGENCY [ttl] drop ${packet.packetId}');
      return;
    }
    await _duplicates.mark(packet.packetId);
    debugPrint('EMERGENCY [rx] ${packet.encode()}');
    _incoming.add(packet);
  }
}
