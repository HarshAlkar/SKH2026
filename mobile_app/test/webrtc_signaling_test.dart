import 'package:flutter_test/flutter_test.dart';
import 'package:hs053/core/services/webrtc_signaling.dart';

void main() {
  test('signalingMap copies nested Socket.IO maps', () {
    final raw = <dynamic, dynamic>{
      'sdp': 'v=0',
      'type': 'offer',
    };
    final mapped = signalingMap(raw);
    expect(mapped, isNotNull);
    expect(mapped!['sdp'], 'v=0');
    expect(mapped['type'], 'offer');
  });

  test('signalingMap rejects non-maps', () {
    expect(signalingMap(null), isNull);
    expect(signalingMap('offer'), isNull);
  });

  test('iceLineIndex coerces JSON numbers to int', () {
    expect(iceLineIndex(0), 0);
    expect(iceLineIndex(1.0), 1);
    expect(iceLineIndex('2'), 2);
    expect(iceLineIndex(null), isNull);
  });

  test('iceCandidateString drops empty end-of-candidates', () {
    expect(iceCandidateString('candidate:1 udp'), 'candidate:1 udp');
    expect(iceCandidateString(''), isNull);
    expect(iceCandidateString(null), isNull);
    expect(iceCandidateString('null'), isNull);
  });
}
