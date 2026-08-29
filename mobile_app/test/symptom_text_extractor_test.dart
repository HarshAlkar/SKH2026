import 'package:flutter_test/flutter_test.dart';
import 'package:hs053/features/ai_symptom_checker/services/symptom_text_extractor.dart';

void main() {
  final vocab = {
    'high_fever',
    'mild_fever',
    'vomiting',
    'nausea',
    'headache',
    'abdominal_pain',
    'muscle_pain',
    'fatigue',
    'cough',
    'yellowing_of_eyes',
    'yellowish_skin',
  };

  test('TEST A: fever and vomiting for 16 days', () {
    final r = SymptomTextExtractor.instance.extract(
      'I have fever and vomiting for 16 days',
      vocabulary: vocab,
    );
    expect(r.extracted, containsAll(['high_fever', 'vomiting']));
    expect(r.extracted, isNot(contains('fever')));
    expect(r.unknown, isFalse);
  });

  test('TEST B: high fever headache body pain', () {
    final r = SymptomTextExtractor.instance.extract(
      'I have high fever, headache and body pain',
      vocabulary: vocab,
    );
    expect(r.extracted, containsAll(['high_fever', 'headache', 'muscle_pain']));
  });

  test('TEST C: throwing up and stomach pain', () {
    final r = SymptomTextExtractor.instance.extract(
      'I am throwing up and have stomach pain',
      vocabulary: vocab,
    );
    expect(r.extracted, containsAll(['vomiting', 'abdominal_pain']));
  });

  test('TEST D: fever but no cough', () {
    final r = SymptomTextExtractor.instance.extract(
      'I have fever but no cough',
      vocabulary: vocab,
    );
    expect(r.extracted, contains('high_fever'));
    expect(r.extracted, isNot(contains('cough')));
    expect(r.suppressed, contains('cough'));
  });

  test('TEST E: vague body feels strange', () {
    final r = SymptomTextExtractor.instance.extract(
      'My body feels strange',
      vocabulary: vocab,
    );
    expect(r.extracted, isEmpty);
    expect(r.unknown || !r.hasEnough, isTrue);
  });
}
