import 'dart:async';

import 'package:flutter/foundation.dart';

import '../emergency_comms_config.dart';
import '../emergency_communication_service.dart';
import '../emergency_mode.dart';
import '../emergency_packet.dart';
import '../reliability/duplicate_filter.dart';
import '../reliability/emergency_queue.dart';
import '../transports/esp32_http_client.dart';

/// Patient phone → ESP32 SoftAP HTTP. Firmware may loop the packet into
/// `/inbox` for a same-AP demo. No LoRa TX is requested.
class LocalWifiEmergencyService implements EmergencyCommunicationService {
  LocalWifiEmergencyService({
    EmergencyQueue? queue,
    DuplicateFilter? duplicates,
    Esp32HttpClient? client,
  })  : _queue = queue ?? EmergencyQueue.instance,
        _duplicates = duplicates ?? DuplicateFilter(),
        _client = client ?? Esp32HttpClient();

  final EmergencyQueue _queue;
  final DuplicateFilter _duplicates;
  final Esp32HttpClient _client;
  final StreamController<EmergencyPacket> _incoming =
      StreamController<EmergencyPacket>.broadcast();

  Timer? _pollTimer;
  Timer? _flushTimer;
  bool _reachable = false;

  @override
  EmergencyMode get mode => EmergencyMode.localWifi;

  @override
  Stream<EmergencyPacket> get incoming => _incoming.stream;

  @override
  bool get gatewayReachable => _reachable;

  @override
  String get statusLabel => _reachable
      ? 'LOCAL_WIFI — ESP32 ${EmergencyCommsConfig.gatewayHost}'
      : 'LOCAL_WIFI — gateway unreachable';

  @override
  Future<void> initialize() async {
    debugPrint('EMERGENCY [init] mode=LOCAL_WIFI gateway=${EmergencyCommsConfig.gatewayOrigin}');
    _reachable = await _client.health();
    debugPrint('EMERGENCY [esp32] health=${_reachable ? 'ok' : 'down'}');
    _pollTimer?.cancel();
    _flushTimer?.cancel();
    _pollTimer = Timer.periodic(EmergencyCommsConfig.inboxPollInterval, (_) => _pollInbox());
    _flushTimer = Timer.periodic(EmergencyCommsConfig.retryBackoff, (_) => _flushQueue());
  }

  @override
  Future<void> dispose() async {
    _pollTimer?.cancel();
    _flushTimer?.cancel();
    _client.close();
    await _incoming.close();
  }

  @override
  Future<EmergencySendResult> send(EmergencyPacket packet) async {
    debugPrint('EMERGENCY [create] ${packet.encode()}');
    await _queue.enqueue(packet);
    debugPrint('EMERGENCY [queue] id=${packet.packetId} seq=${packet.seq}');
    final delivered = await _attempt(packet);
    if (delivered) {
      await _queue.markAcked(packet.packetId);
      return EmergencySendResult(
        queued: true,
        delivered: true,
        packetId: packet.packetId,
        message: 'Delivered to ESP32 gateway (local Wi-Fi)',
      );
    }
    return EmergencySendResult(
      queued: true,
      delivered: false,
      packetId: packet.packetId,
      message: 'Queued — ESP32 gateway unreachable, will retry',
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
    debugPrint('EMERGENCY [wifi] TX → ${EmergencyCommsConfig.gatewayOrigin}/emergency');
    final ok = await _client.postEmergency(packet, forwardLora: false);
    _reachable = ok || await _client.health();
    if (!ok) {
      await _queue.markRetry(packet.packetId, 'gateway unreachable');
      debugPrint('EMERGENCY [wifi] no ACK — leaving in queue');
    } else {
      debugPrint('EMERGENCY [wifi] ACK id=${packet.packetId}');
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
