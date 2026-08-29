import 'package:flutter/foundation.dart';

/// Offline symptom phrase extractor / normalizer for free-text descriptions.
/// Maps natural language onto the trained multi-hot vocabulary — does not diagnose.
class SymptomTextExtractor {
  SymptomTextExtractor._();
  static final SymptomTextExtractor instance = SymptomTextExtractor._();

  /// Phrase (lowercase) → feature token used in training.
  /// Must match keys in symptom_labels.json features (e.g. high_fever, not fever).
  static const Map<String, String> phraseMap = {
    'high fever': 'high_fever',
    'very high fever': 'high_fever',
    'high temperature': 'high_fever',
    'feeling very hot': 'high_fever',
    'fever': 'high_fever',
    'temperature': 'high_fever',
    'feeling hot': 'high_fever',
    'mild fever': 'mild_fever',
    'have been vomiting': 'vomiting',
    'throwing up': 'vomiting',
    'threw up': 'vomiting',
    'vomit': 'vomiting',
    'vomiting': 'vomiting',
    'feel like vomiting': 'nausea',
    'nauseous': 'nausea',
    'nausea': 'nausea',
    'stomach pain': 'abdominal_pain',
    'pain in stomach': 'abdominal_pain',
    'belly pain': 'abdominal_pain',
    'abdominal pain': 'abdominal_pain',
    'pain in my belly': 'abdominal_pain',
    'tummy pain': 'abdominal_pain',
    'stomach ache': 'abdominal_pain',
    'headache': 'headache',
    'head hurts': 'headache',
    'my head hurts': 'headache',
    'pain in head': 'headache',
    'pain in my head': 'headache',
    'migraine': 'headache',
    'fatigue': 'fatigue',
    'very tired': 'fatigue',
    'feel very tired': 'fatigue',
    'feeling tired': 'fatigue',
    'tired': 'fatigue',
    'weakness': 'fatigue',
    'loss of appetite': 'loss_of_appetite',
    'no appetite': 'loss_of_appetite',
    'not eating': 'loss_of_appetite',
    'chills': 'chills',
    'shivering': 'chills',
    'yellowish skin': 'yellowish_skin',
    'yellow skin': 'yellowish_skin',
    'my eyes are yellow': 'yellowing_of_eyes',
    'eyes are yellow': 'yellowing_of_eyes',
    'yellowing of eyes': 'yellowing_of_eyes',
    'yellow eyes': 'yellowing_of_eyes',
    'yellow eye': 'yellowing_of_eyes',
    'jaundice': 'yellowish_skin',
    'cough': 'cough',
    'coughing': 'cough',
    "can't breathe": 'breathlessness',
    'cannot breathe': 'breathlessness',
    'breathing problem': 'breathlessness',
    'breathing difficulty': 'breathlessness',
    'shortness of breath': 'breathlessness',
    'short of breath': 'breathlessness',
    'breathlessness': 'breathlessness',
    'chest pain': 'chest_pain',
    'pain in chest': 'chest_pain',
    'diarrhea': 'diarrhoea',
    'diarrhoea': 'diarrhoea',
    'loose stools': 'diarrhoea',
    'itching': 'itching',
    'itchy': 'itching',
    'skin rash': 'skin_rash',
    'rash': 'skin_rash',
    'sneezing': 'continuous_sneezing',
    'runny nose': 'continuous_sneezing',
    'body pain': 'muscle_pain',
    'बुखार': 'high_fever',
    'तेज बुखार': 'high_fever',
    'ताप': 'high_fever',
    'खांसी': 'cough',
    'खोकला': 'cough',
    'सिरदर्द': 'headache',
    'डोकेदुखी': 'headache',
    'उल्टी': 'vomiting',
    'उलटी': 'vomiting',
    'दस्त': 'diarrhoea',
    'जुलाब': 'diarrhoea',
    'सांस': 'breathlessness',
    'श्वास': 'breathlessness',
    'खुजली': 'itching',
    'खाज': 'itching',
    'चकत्ते': 'skin_rash',
    'पुरळ': 'skin_rash',
    'body ache': 'muscle_pain',
    'muscle pain': 'muscle_pain',
    'joint pain': 'joint_pain',
    'sweating': 'sweating',
    'weight loss': 'weight_loss',
    'dizziness': 'dizziness',
    'dizzy': 'dizziness',
  };

  static final _negation = RegExp(
    r"\b(no|not|without|don't|dont|never|nor)\b",
    caseSensitive: false,
  );

  /// Duration / time phrases are not symptoms.
  static final _durationNoise = RegExp(
    r'\bfor\s+\d+\s*(day|days|week|weeks|month|months|hour|hours)\b'
    r'|\b\d+\s*(day|days|week|weeks|month|months|hour|hours)\b'
    r'|\bsince\s+(yesterday|today|last\s+\w+)\b',
    caseSensitive: false,
  );

  /// Longer phrases first so "high fever" wins over "fever".
  static final List<MapEntry<String, String>> _sortedPhrases = () {
    final entries = phraseMap.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    return entries;
  }();

  SymptomExtractionResult extract(
    String text, {
    Set<String>? vocabulary,
  }) {
    var normalized = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), ' ');
    normalized = normalized.replaceAll(_durationNoise, ' ');
    final collapsed = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.isEmpty) {
      return const SymptomExtractionResult(
        extracted: [],
        suppressed: [],
        unknown: true,
      );
    }

    const vague = {
      'strange',
      'weird',
      'odd',
      'not well',
      'unwell',
      'sick',
      'bad',
    };
    final words = collapsed.split(' ');
    final onlyVague = words.every(
      (w) =>
          vague.contains(w) ||
          {
            'my',
            'body',
            'feels',
            'feeling',
            'i',
            'am',
            'a',
            'the',
            'and',
            'or',
            'have',
            'been',
          }.contains(w),
    );

    final extracted = <String>{};
    final suppressed = <String>{};
    final matchedSpans = <String>[];

    for (final entry in _sortedPhrases) {
      final phrase = entry.key;
      final token = entry.value;
      if (vocabulary != null &&
          vocabulary.isNotEmpty &&
          !vocabulary.contains(token)) {
        continue;
      }
      final pattern = RegExp('\\b${RegExp.escape(phrase)}\\b');
      for (final m in pattern.allMatches(collapsed)) {
        matchedSpans.add(phrase);
        final start = mathMax(0, m.start - 28);
        final window = collapsed.substring(start, m.start);
        if (_negation.hasMatch(window)) {
          suppressed.add(token);
        } else {
          extracted.add(token);
        }
      }
    }

    extracted.removeAll(suppressed);

    final unknown = extracted.isEmpty &&
        (onlyVague ||
            matchedSpans.isEmpty &&
                collapsed.split(' ').where((w) => w.length > 3).length >= 2);

    if (kDebugMode) {
      debugPrint(
        'SymptomTextExtractor raw="$text" '
        'extracted=$extracted suppressed=$suppressed unknown=$unknown',
      );
    }

    return SymptomExtractionResult(
      extracted: extracted.toList()..sort(),
      suppressed: suppressed.toList()..sort(),
      unknown: unknown,
      matchedPhrases: matchedSpans.toSet().toList(),
    );
  }

  static int mathMax(int a, int b) => a > b ? a : b;
}

class SymptomExtractionResult {
  final List<String> extracted;
  final List<String> suppressed;
  final bool unknown;
  final List<String> matchedPhrases;

  const SymptomExtractionResult({
    required this.extracted,
    required this.suppressed,
    this.unknown = false,
    this.matchedPhrases = const [],
  });

  bool get hasEnough => extracted.isNotEmpty;
}
