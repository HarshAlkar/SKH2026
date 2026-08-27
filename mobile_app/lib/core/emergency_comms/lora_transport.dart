/// Hardware-facing radio abstraction. The Flutter app talks HTTP to an
/// ESP32; the ESP32 firmware implements this interface against the module.
///
/// A Dart implementation exists so a future serial/USB bridge can replace
/// HTTP without changing SOS UI. Do not hard-code a specific LoRa chip.
abstract class LoRaTransport {
  Future<void> initialize();
  Future<bool> send(List<int> packet);
  Future<List<int>?> receive({Duration timeout = const Duration(seconds: 2)});
  bool get isConnected;
  LoRaSignalStatus getSignalStatus();
  Future<void> dispose();
}

class LoRaSignalStatus {
  final bool linked;
  final int? rssi;
  final double? snr;
  final String detail;

  const LoRaSignalStatus({
    required this.linked,
    this.rssi,
    this.snr,
    this.detail = '',
  });

  static const disconnected = LoRaSignalStatus(
    linked: false,
    detail: 'No LoRa radio connected',
  );
}
