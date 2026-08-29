import 'package:flutter_test/flutter_test.dart';
import 'package:hs053/features/ai_symptom_checker/services/symptom_text_extractor.dart';

void main() {
  final extractor = SymptomTextExtractor.instance;

  test('TEST1 high fever headache vomiting', () {
    final r = extractor.extract(
      'I have high fever, headache and vomiting.',
    );
    expect(r.extracted, containsAll(['high_fever', 'headache', 'vomiting']));
  });

  test('TEST2 stomach pain tired', () {
    final r = extractor.extract(
      'I have stomach pain and feel very tired.',
    );
    expect(r.extracted, containsAll(['abdominal_pain', 'fatigue']));
  });

  test('TEST3 fever but no cough', () {
    final r = extractor.extract('I have fever but no cough.');
    expect(r.extracted, contains('fever'));
    expect(r.extracted, isNot(contains('cough')));
    expect(r.suppressed, contains('cough'));
  });

  test('TEST4 throwing up belly', () {
    final r = extractor.extract(
      'Throwing up, headache and pain in my belly.',
    );
    expect(r.extracted, containsAll(['vomiting', 'headache', 'abdominal_pain']));
  });

  test('TEST5 vague body strange', () {
    final r = extractor.extract('My body feels strange.');
    expect(r.extracted, isEmpty);
  });
}
