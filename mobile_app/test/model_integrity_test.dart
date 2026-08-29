import 'package:flutter_test/flutter_test.dart';
import 'package:hs053/core/security/model_integrity.dart';

void main() {
  test('ModelIntegrity.hashBytes is stable SHA-256', () {
    final a = ModelIntegrity.hashBytes([1, 2, 3]);
    final b = ModelIntegrity.hashBytes([1, 2, 3]);
    expect(a, b);
    expect(a.length, 64);
  });
}
