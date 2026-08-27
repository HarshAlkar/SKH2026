import 'emergency_mode.dart';
import 'emergency_packet.dart';

abstract class EmergencyCommunicationService {
  EmergencyMode get mode;
  Stream<EmergencyPacket> get incoming;
  bool get gatewayReachable;
  String get statusLabel;

  Future<void> initialize();
  Future<void> dispose();

  /// Queue and attempt to send a high-priority emergency packet.
  /// Never depends on Internet, Django, or Firebase.
  Future<EmergencySendResult> send(EmergencyPacket packet);

  Future<void> acknowledge(EmergencyPacket packet);

  /// Dev/test: push a packet into the same incoming stream the ESP32
  /// inbox poller will use when hardware is present.
  Future<void> injectSimulatedIncoming(EmergencyPacket packet);
}
