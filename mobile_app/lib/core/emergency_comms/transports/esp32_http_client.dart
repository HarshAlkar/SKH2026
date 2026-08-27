import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../emergency_comms_config.dart';
import '../emergency_packet.dart';

/// Phone ↔ ESP32 gateway over the local SoftAP. Independent of Django
/// [ApiService]: no auth token, short timeout, no cloud host.
class Esp32HttpClient {
  Esp32HttpClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) {
    final origin = EmergencyCommsConfig.gatewayOrigin;
    return Uri.parse('$origin$path');
  }

  Future<bool> health() async {
    try {
      final res = await _client.get(_uri('/health')).timeout(EmergencyCommsConfig.httpTimeout);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('EMERGENCY [esp32] health failed: $e');
      return false;
    }
  }

  /// POST compact packet. [forwardLora] tells firmware to TX on the radio
  /// when a module is wired; ignored in firmware MOCK mode.
  Future<bool> postEmergency(EmergencyPacket packet, {required bool forwardLora}) async {
    final body = jsonEncode({
      'fwd': forwardLora ? 'lora' : 'wifi',
      'pkt': packet.toCompactJson(),
    });
    debugPrint('EMERGENCY [esp32] POST /emergency fwd=${forwardLora ? 'lora' : 'wifi'} $body');
    try {
      final res = await _client
          .post(
            _uri('/emergency'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(EmergencyCommsConfig.httpTimeout);
      debugPrint('EMERGENCY [esp32] POST /emergency → ${res.statusCode} ${res.body}');
      if (res.statusCode < 200 || res.statusCode >= 300) return false;
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['ack'] == true) return true;
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('EMERGENCY [esp32] POST /emergency failed: $e');
      return false;
    }
  }

  Future<List<EmergencyPacket>> fetchInbox() async {
    try {
      final res = await _client.get(_uri('/inbox')).timeout(EmergencyCommsConfig.httpTimeout);
      if (res.statusCode != 200) return const [];
      final decoded = jsonDecode(res.body);
      final list = decoded is Map ? decoded['packets'] : decoded;
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((e) => EmergencyPacket.fromCompactJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('EMERGENCY [esp32] GET /inbox failed: $e');
      return const [];
    }
  }

  Future<bool> postAck(EmergencyAck ack) async {
    debugPrint('EMERGENCY [esp32] POST /ack ${ack.encode()}');
    try {
      final res = await _client
          .post(
            _uri('/ack'),
            headers: {'Content-Type': 'application/json'},
            body: ack.encode(),
          )
          .timeout(EmergencyCommsConfig.httpTimeout);
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      debugPrint('EMERGENCY [esp32] POST /ack failed: $e');
      return false;
    }
  }

  void close() => _client.close();
}
