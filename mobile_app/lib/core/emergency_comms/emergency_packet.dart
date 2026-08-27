import 'dart:convert';
import 'dart:math';

import '../../models/user_model.dart';

/// Compact LoRa-oriented emergency packet. Short keys keep the payload
/// under a typical SX127x 255-byte limit (target ~200 bytes JSON).
class EmergencyPacket {
  static const int protocolVersion = 1;
  static const int emergencyPriority = 9;

  final int version;
  final String packetId;
  final int seq;
  final String eventId;
  final int patientId;
  final int timestamp;
  final String type;
  final int priority;
  final double? latitude;
  final double? longitude;
  final String name;
  final int? age;
  final String village;
  final String? phone;
  final int ttl;

  const EmergencyPacket({
    this.version = protocolVersion,
    required this.packetId,
    required this.seq,
    required this.eventId,
    required this.patientId,
    required this.timestamp,
    this.type = 'sos',
    this.priority = emergencyPriority,
    this.latitude,
    this.longitude,
    this.name = '',
    this.age,
    this.village = '',
    this.phone,
    required this.ttl,
  });

  bool get isExpired {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= ttl;
  }

  String get locationLabel {
    if (latitude == null || longitude == null) return '';
    return '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}';
  }

  Map<String, dynamic> toCompactJson() {
    final map = <String, dynamic>{
      'v': version,
      'id': packetId,
      'seq': seq,
      'eid': eventId,
      'pid': patientId,
      'ts': timestamp,
      'typ': type,
      'pri': priority,
      'ttl': ttl,
    };
    if (latitude != null) map['lat'] = double.parse(latitude!.toStringAsFixed(4));
    if (longitude != null) map['lng'] = double.parse(longitude!.toStringAsFixed(4));
    if (name.isNotEmpty) map['n'] = name;
    if (age != null) map['age'] = age;
    if (village.isNotEmpty) map['vil'] = village;
    if (phone != null && phone!.isNotEmpty) map['ph'] = phone;
    return map;
  }

  String encode() => jsonEncode(toCompactJson());

  List<int> encodeBytes() => utf8.encode(encode());

  factory EmergencyPacket.fromCompactJson(Map<String, dynamic> json) {
    return EmergencyPacket(
      version: asInt(json['v']) ?? protocolVersion,
      packetId: json['id']?.toString() ?? '',
      seq: asInt(json['seq']) ?? 0,
      eventId: json['eid']?.toString() ?? '',
      patientId: asInt(json['pid']) ?? 0,
      timestamp: asInt(json['ts']) ?? 0,
      type: json['typ']?.toString() ?? 'sos',
      priority: asInt(json['pri']) ?? emergencyPriority,
      latitude: asDouble(json['lat']),
      longitude: asDouble(json['lng']),
      name: json['n']?.toString() ?? '',
      age: asInt(json['age']),
      village: json['vil']?.toString() ?? '',
      phone: json['ph']?.toString(),
      ttl: asInt(json['ttl']) ?? 0,
    );
  }

  factory EmergencyPacket.decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Emergency packet is not a JSON object');
    }
    return EmergencyPacket.fromCompactJson(Map<String, dynamic>.from(decoded));
  }

  factory EmergencyPacket.fromBytes(List<int> bytes) {
    return EmergencyPacket.decode(utf8.decode(bytes));
  }

  factory EmergencyPacket.fromPatient({
    required UserModel user,
    required int seq,
    required int ttlSeconds,
    double? latitude,
    double? longitude,
    String type = 'sos',
    int priority = emergencyPriority,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final ageRaw = user.detail('age');
    return EmergencyPacket(
      packetId: shortId(),
      seq: seq,
      eventId: shortId(),
      patientId: user.id,
      timestamp: now,
      type: type,
      priority: priority,
      latitude: latitude,
      longitude: longitude,
      name: clip(user.name, 20),
      age: int.tryParse(ageRaw),
      village: clip(user.village, 16),
      phone: clip(user.phoneNumber, 15),
      ttl: now + ttlSeconds,
    );
  }

  /// Developer-facing sample used by "Simulate incoming packet".
  factory EmergencyPacket.simulated({required int seq, required int ttlSeconds}) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return EmergencyPacket(
      packetId: shortId(),
      seq: seq,
      eventId: shortId(),
      patientId: 0,
      timestamp: now,
      type: 'sos',
      priority: emergencyPriority,
      latitude: 28.6139,
      longitude: 77.2090,
      name: 'Simulated Patient',
      age: 42,
      village: 'Rampur',
      phone: '9999999999',
      ttl: now + ttlSeconds,
    );
  }

  EmergencyAck ack() => EmergencyAck(
        packetId: packetId,
        seq: seq,
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );

  static String shortId() {
    final n = Random.secure().nextInt(0xFFFFFFFF);
    return n.toRadixString(16).padLeft(8, '0');
  }

  static String clip(String value, int max) {
    final trimmed = value.trim();
    if (trimmed.length <= max) return trimmed;
    return trimmed.substring(0, max);
  }

  static int? asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class EmergencyAck {
  final String packetId;
  final int seq;
  final int timestamp;

  const EmergencyAck({
    required this.packetId,
    required this.seq,
    required this.timestamp,
  });

  Map<String, dynamic> toCompactJson() => {
        'v': EmergencyPacket.protocolVersion,
        'id': packetId,
        'seq': seq,
        'ack': true,
        'ts': timestamp,
      };

  String encode() => jsonEncode(toCompactJson());

  factory EmergencyAck.fromCompactJson(Map<String, dynamic> json) {
    return EmergencyAck(
      packetId: json['id']?.toString() ?? '',
      seq: EmergencyPacket.asInt(json['seq']) ?? 0,
      timestamp: EmergencyPacket.asInt(json['ts']) ?? 0,
    );
  }
}

class EmergencySendResult {
  /// True when the packet was accepted into the local high-priority queue.
  final bool queued;

  /// True only when an ACK was received from the current transport.
  /// Mock mode may ACK after a simulated hop; hardware modes never fake this.
  final bool delivered;

  final String message;
  final String packetId;

  const EmergencySendResult({
    required this.queued,
    required this.delivered,
    required this.message,
    required this.packetId,
  });
}
