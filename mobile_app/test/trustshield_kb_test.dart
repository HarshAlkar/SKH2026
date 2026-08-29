import 'package:flutter_test/flutter_test.dart';
import 'package:hs053/core/trustshield/trusted_knowledge_base.dart';
import 'package:hs053/core/trustshield/trustshield_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dengue antibiotics is misleading high risk', () async {
    final r = await TrustedKnowledgeBase.instance.verifyLocal(
      'WhatsApp says antibiotics cure dengue in two days.',
    );
    expect(r.status, ClaimStatus.misleading);
    expect(r.riskLevel, RiskLevel.high);
    expect(r.offline, isTrue);
    expect(r.sources, isNotEmpty);
  });

  test('handwash is verified', () async {
    final r = await TrustedKnowledgeBase.instance.verifyLocal(
      'Washing hands with soap helps reduce infection risk.',
    );
    expect(r.status, ClaimStatus.verified);
  });

  test('drinking water typo is verified', () async {
    final r = await TrustedKnowledgeBase.instance.verifyLocal(
      'DRINKIN WATER IS GOOD FOR HEALTH',
    );
    expect(r.status, ClaimStatus.verified);
    expect(r.riskLevel, RiskLevel.low);
  });

  test('obscure claim is unverified', () async {
    final r = await TrustedKnowledgeBase.instance.verifyLocal(
      'A rare mineral tea reverses all heart disease overnight without doctors.',
    );
    expect(r.status, ClaimStatus.unverified);
  });

  test('empty is unverified', () async {
    final r = await TrustedKnowledgeBase.instance.verifyLocal('  ');
    expect(r.status, ClaimStatus.unverified);
  });
}
