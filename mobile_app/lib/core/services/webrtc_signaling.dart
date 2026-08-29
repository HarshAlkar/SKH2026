/// Safe casts for Socket.IO / JSON signaling payloads.
Map<String, dynamic>? signalingMap(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

int? iceLineIndex(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

String? iceCandidateString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty || text == 'null') return null;
  return text;
}
