import 'package:flutter/foundation.dart';

import '../lora_transport.dart';

/// In-process stand-in for a LoRa radio. Logs hops and delays; never reports
/// a real RF link. Used only while hardware is unavailable.
class MockLoRaTransport implements LoRaTransport {
  bool _ready = false;

  @override
  Future<void> initialize() async {
    _ready = true;
    debugPrint('EMERGENCY [lora-mock] initialize — simulation only, no radio');
  }

  @override
  Future<bool> send(List<int> packet) async {
    debugPrint(
      'EMERGENCY [lora-mock] send ${packet.length} bytes (NOT transmitted over air)',
    );
    await Future<void>.delayed(const Duration(milliseconds: 180));
    // Simulated hop only. Callers must not treat this as RF success.
    return true;
  }

  @override
  Future<List<int>?> receive({Duration timeout = const Duration(seconds: 2)}) async {
    await Future<void>.delayed(timeout);
    return null;
  }

  @override
  bool get isConnected => _ready;

  @override
  LoRaSignalStatus getSignalStatus() => const LoRaSignalStatus(
        linked: false,
        detail: 'Mock transport — radio not present',
      );

  @override
  Future<void> dispose() async {
    _ready = false;
  }
}
