import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/user_model.dart';
import 'emergency_comms_config.dart';
import 'emergency_communication_service.dart';
import 'emergency_mode.dart';
import 'emergency_packet.dart';
import 'reliability/emergency_queue.dart';
import 'services/local_wifi_emergency_service.dart';
import 'services/lora_emergency_service.dart';
import 'services/mock_emergency_service.dart';

/// App-facing factory. Screens talk to [service], never to LoRa hardware.
class EmergencyComms extends ChangeNotifier {
  EmergencyComms._();
  static final EmergencyComms instance = EmergencyComms._();

  EmergencyCommunicationService? _service;
  StreamSubscription<EmergencyPacket>? _incomingSub;
  final StreamController<EmergencyPacket> _incoming =
      StreamController<EmergencyPacket>.broadcast();
  bool _ready = false;

  bool get isReady => _ready;
  EmergencyCommunicationService get service {
    final current = _service;
    if (current == null) {
      throw StateError('EmergencyComms.initialize() has not run');
    }
    return current;
  }

  EmergencyMode get mode => _service?.mode ?? EmergencyCommsConfig.mode;
  String get statusLabel => _service?.statusLabel ?? 'Offline emergency not started';
  bool get gatewayReachable => _service?.gatewayReachable ?? false;
  Stream<EmergencyPacket> get incoming => _incoming.stream;

  Future<void> initialize() async {
    await EmergencyQueue.instance.database;
    await _start(EmergencyCommsConfig.mode);
    _ready = true;
    notifyListeners();
  }

  Future<void> setMode(EmergencyMode mode) async {
    await EmergencyCommsConfig.setMode(mode);
    await _start(mode);
    notifyListeners();
  }

  Future<void> setGatewayHost(String host) async {
    await EmergencyCommsConfig.setGatewayHost(host);
    await _start(EmergencyCommsConfig.mode);
    notifyListeners();
  }

  Future<int> nextSequence() => EmergencyQueue.instance.nextSequence();

  Future<EmergencyPacket> buildPatientPacket({
    required UserModel user,
    double? latitude,
    double? longitude,
    String type = 'sos',
  }) async {
    final seq = await nextSequence();
    return EmergencyPacket.fromPatient(
      user: user,
      seq: seq,
      ttlSeconds: EmergencyCommsConfig.ttlSeconds,
      latitude: latitude,
      longitude: longitude,
      type: type,
    );
  }

  Future<EmergencySendResult> send(EmergencyPacket packet) {
    return service.send(packet);
  }

  Future<void> acknowledge(EmergencyPacket packet) {
    return service.acknowledge(packet);
  }

  Future<void> injectSimulatedIncoming([EmergencyPacket? packet]) async {
    final seq = await nextSequence();
    final payload = packet ??
        EmergencyPacket.simulated(
          seq: seq,
          ttlSeconds: EmergencyCommsConfig.ttlSeconds,
        );
    debugPrint('EMERGENCY [dev] inject simulated incoming ${payload.encode()}');
    await service.injectSimulatedIncoming(payload);
  }

  Future<void> _start(EmergencyMode mode) async {
    await _incomingSub?.cancel();
    await _service?.dispose();
    _service = _create(mode);
    await _service!.initialize();
    _incomingSub = _service!.incoming.listen(_incoming.add);
    debugPrint('EMERGENCY [factory] active=${mode.wireName} ${_service!.statusLabel}');
  }

  EmergencyCommunicationService _create(EmergencyMode mode) {
    switch (mode) {
      case EmergencyMode.localWifi:
        return LocalWifiEmergencyService();
      case EmergencyMode.lora:
        return LoRaEmergencyService();
      case EmergencyMode.mock:
        return MockEmergencyService();
    }
  }
}
