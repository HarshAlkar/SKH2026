import 'dart:math' as math;

import 'package:flutter/services.dart';

/// Loads `lib/dataset/disease/dataset.csv` and runs on-device screening
/// aligned with `ai_engine/predict.py`.
class SymptomDatasetService {
  SymptomDatasetService._();
  static final SymptomDatasetService instance = SymptomDatasetService._();

  static const _assetPath = 'lib/dataset/disease/dataset.csv';

  static const _aliases = <String, String>{
    'temp': 'high_fever',
    'temperature': 'high_fever',
    'fever': 'high_fever',
    'cough': 'cough',
    'rash': 'skin_rash',
    'itch': 'itching',
    'itching': 'itching',
    'headache': 'headache',
    'vomit': 'vomiting',
    'vomiting': 'vomiting',
    'nausea': 'nausea',
    'fatigue': 'fatigue',
    'tired': 'fatigue',
    'chest': 'chest_pain',
    'chest_pain': 'chest_pain',
    'breath': 'breathlessness',
    'breathing': 'breathlessness',
    'diarrhea': 'diarrhoea',
    'diarrhoea': 'diarrhoea',
    'cold': 'continuous_sneezing',
    'sneeze': 'continuous_sneezing',
    'high_fever': 'high_fever',
  };

  static const _commonRespiratory = {
    'high_fever',
    'mild_fever',
    'fever',
    'cough',
    'headache',
    'fatigue',
    'continuous_sneezing',
  };

  static const _confidenceFloor = 0.35;

  static const _skinTokens = {
    'itching',
    'skin_rash',
    'nodal_skin_eruptions',
    'dischromic_patches',
    'yellowish_skin',
    'yellowing_of_eyes',
    'blister',
    'red_sore_around_nose',
    'pus_filled_pimples',
    'blackheads',
    'scurring',
    'skin_peeling',
    'silver_like_dusting',
    'small_dents_in_nails',
    'inflammatory_nails',
    'patches_in_throat',
  };

  static const _skinDiseases = {
    'fungal infection',
    'acne',
    'impetigo',
    'psoriasis',
    'drug reaction',
    'chicken pox',
    'jaundice',
  };

  static const _severityHigh = {
    'pneumonia',
    'heart attack',
    'jaundice',
    'malaria',
    'dengue',
    'typhoid',
    'tuberculosis',
    'hepatitis',
    'aids',
    'paralysis',
  };

  static const _severityCritical = {'heart attack', 'paralysis'};

  static const _severityModerate = {
    'fungal infection',
    'hypertension',
    'diabetes',
    'migraine',
    'bronchial asthma',
    'gerd',
    'common cold',
    'possible viral illness',
    'acne',
    'impetigo',
    'psoriasis',
    'drug reaction',
  };

  static const _symptomLabelsEn = {
    'fatigue': 'Fatigue',
    'vomiting': 'Vomiting',
    'high_fever': 'High Fever',
    'loss_of_appetite': 'Loss of Appetite',
    'nausea': 'Nausea',
    'headache': 'Headache',
    'abdominal_pain': 'Abdominal Pain',
    'yellowish_skin': 'Yellowish Skin',
    'yellowing_of_eyes': 'Yellowing of Eyes',
    'chills': 'Chills',
    'skin_rash': 'Skin Rash',
    'malaise': 'Malaise',
    'chest_pain': 'Chest Pain',
    'joint_pain': 'Joint Pain',
    'itching': 'Itching',
    'sweating': 'Sweating',
    'dark_urine': 'Dark Urine',
    'cough': 'Cough',
    'diarrhoea': 'Diarrhoea',
    'irritability': 'Irritability',
    'fever': 'Fever',
    'continuous_sneezing': 'Sneezing',
    'breathlessness': 'Breathlessness',
    'nodal_skin_eruptions': 'Skin Eruptions',
    'dischromic_patches': 'Discolored Patches',
    'blister': 'Blisters',
    'pus_filled_pimples': 'Pus-filled Pimples',
    'skin_peeling': 'Skin Peeling',
  };

  static const _symptomLabelsHi = {
    'fatigue': 'थकान',
    'vomiting': 'उल्टी',
    'high_fever': 'तेज बुखार',
    'loss_of_appetite': 'भूख न लगना',
    'nausea': 'मितली',
    'headache': 'सिरदर्द',
    'abdominal_pain': 'पेट दर्द',
    'yellowish_skin': 'पीली त्वचा',
    'yellowing_of_eyes': 'आँखों का पीलापन',
    'chills': 'ठंड लगना',
    'skin_rash': 'चकत्ते',
    'malaise': 'बेचैनी',
    'chest_pain': 'सीने में दर्द',
    'joint_pain': 'जोड़ों का दर्द',
    'itching': 'खुजली',
    'sweating': 'पसीना',
    'dark_urine': 'गहरे रंग का पेशाब',
    'cough': 'खांसी',
    'diarrhoea': 'दस्त',
    'irritability': 'चिड़चिड़ापन',
    'fever': 'बुखार',
    'continuous_sneezing': 'छींक',
    'breathlessness': 'सांस फूलना',
    'nodal_skin_eruptions': 'त्वचा पर फोड़े',
    'dischromic_patches': 'रंग बदलने वाले धब्बे',
    'blister': 'छाले',
    'pus_filled_pimples': 'मवाद भरे फुंसी',
    'skin_peeling': 'त्वचा का छिलना',
  };

  bool _loaded = false;
  final List<_DiseaseRow> _rows = [];
  final Map<String, int> _symptomFrequency = {};

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString(_assetPath);
    _parseCsv(raw);
    _loaded = true;
  }

  Future<List<SymptomOption>> commonSymptoms({int limit = 18}) async {
    await ensureLoaded();
    final ranked = _symptomFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ranked.take(limit).map((entry) {
      final token = entry.key;
      return SymptomOption(
        token: token,
        labelEn: _symptomLabelsEn[token] ?? _titleCase(token),
        labelHi: _symptomLabelsHi[token] ?? _titleCase(token),
      );
    }).toList();
  }

  Future<List<SymptomOption>> skinSymptoms() async {
    await ensureLoaded();
    final available = _skinTokens.where(_symptomFrequency.containsKey).toList();
    return available.map((token) {
      return SymptomOption(
        token: token,
        labelEn: _symptomLabelsEn[token] ?? _titleCase(token),
        labelHi: _symptomLabelsHi[token] ?? _titleCase(token),
      );
    }).toList();
  }

  Future<Map<String, dynamic>?> predict(
    List<String> inputs, {
    bool skinOnly = false,
    String language = 'en',
  }) async {
    await ensureLoaded();
    final tokens = _normalizeInputs(inputs);
    if (tokens.isEmpty) return null;

    final present = tokens.toSet();
    final scores = <String, double>{};

    for (final row in _rows) {
      if (skinOnly && !_skinDiseases.contains(row.disease.toLowerCase().trim())) {
        continue;
      }
      final unique = row.symptoms.toSet();
      if (unique.isEmpty) continue;
      final matches = present.intersection(unique).length;
      if (matches == 0) continue;
      final coverage = matches / unique.length;
      final current = scores[row.disease] ?? 0;
      if (coverage > current) scores[row.disease] = coverage;
    }

    if (scores.isEmpty) {
      return _undetermined(tokens, language: language, skinOnly: skinOnly);
    }

    final ranked = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    // Softmax over top coverages so UI never shows multiple 100% "confidences".
    final topRaw = ranked.where((entry) => entry.value >= _confidenceFloor).take(5).toList();
    if (topRaw.isEmpty) {
      return _undetermined(tokens, language: language, skinOnly: skinOnly);
    }
    final onlyCommon = present.isNotEmpty && present.every(_commonRespiratory.contains);
    if (onlyCommon && !skinOnly) {
      return _undetermined(tokens, language: language, skinOnly: false);
    }

    final exps = topRaw.map((e) => math.exp((e.value * 3).clamp(-20.0, 20.0))).toList();
    final eSum = exps.fold<double>(0, (a, b) => a + b);
    final top = <Map<String, dynamic>>[];
    for (var i = 0; i < topRaw.length && top.length < 3; i++) {
      final entry = topRaw[i];
      final displayScore = eSum > 0 ? exps[i] / eSum : 0.0;
      top.add({
        'disease': entry.key,
        'confidence': _round3(displayScore),
        'match_coverage': _round3(entry.value),
        'severity': _severityFor(entry.key),
      });
    }

    final best = top.first;
    return {
      'disease': best['disease'],
      'possible_condition': 'Elevated-risk screening result (fallback)',
      'disease_display': 'Elevated-risk screening result (fallback)',
      'severity': best['severity'],
      'confidence': best['confidence'],
      'top_predictions': top,
      'alert_sent': false,
      'source': skinOnly ? 'dataset_skin' : 'dataset_local',
      'score_type': 'symptom_match_fallback',
      'result_state': 'SUCCESS_FALLBACK',
      'headline': 'Symptom-match screening (fallback)',
      'advice': _adviceFor(best['disease'] as String, language: language),
      'disclaimer': _disclaimer(language),
      'message':
          'On-device ML was unavailable; this ranked list uses symptom matching only — '
          'not model probabilities. AI-assisted screening only. This is not a medical diagnosis.',
      'language': language.startsWith('hi') ? 'hi' : 'en',
    };
  }

  void _parseCsv(String raw) {
    _rows.clear();
    _symptomFrequency.clear();
    final lines = raw.split(RegExp(r'\r?\n'));
    if (lines.isEmpty) return;

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final parts = _splitCsvLine(line);
      if (parts.isEmpty) continue;
      final disease = parts.first.trim();
      final symptoms = <String>[];
      for (final part in parts.skip(1)) {
        final token = _normalizeToken(part);
        if (token.isEmpty) continue;
        symptoms.add(token);
        _symptomFrequency[token] = (_symptomFrequency[token] ?? 0) + 1;
      }
      if (symptoms.isNotEmpty) {
        _rows.add(_DiseaseRow(disease: disease, symptoms: symptoms));
      }
    }
  }

  List<String> _splitCsvLine(String line) {
    final parts = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
        continue;
      }
      if (char == ',' && !inQuotes) {
        parts.add(buffer.toString());
        buffer.clear();
        continue;
      }
      buffer.write(char);
    }
    parts.add(buffer.toString());
    return parts;
  }

  List<String> _normalizeInputs(List<String> inputs) {
    final ordered = <String>[];
    final seen = <String>{};
    for (final item in inputs) {
      final chunks = item
          .toLowerCase()
          .split(RegExp(r'[,\s/]+'))
          .map(_normalizeToken)
          .where((s) => s.isNotEmpty)
          .toList();
      // Prefer whole-phrase token when it is a known symptom key.
      final whole = _normalizeToken(item);
      final sequence = <String>[];
      if (whole.isNotEmpty && (chunks.length > 1 || chunks.isEmpty)) {
        sequence.add(whole);
      }
      sequence.addAll(chunks);
      for (final token in sequence) {
        if (token.isEmpty || seen.contains(token)) continue;
        seen.add(token);
        ordered.add(token);
        final alias = _aliases[token];
        if (alias != null && seen.add(alias)) ordered.add(alias);
        for (final part in token.split('_')) {
          final partAlias = _aliases[part];
          if (partAlias != null && seen.add(partAlias)) ordered.add(partAlias);
        }
      }
    }

    // Bigrams only for distinct adjacent tokens (never vomiting_vomiting).
    final withBigrams = List<String>.from(ordered);
    for (var i = 0; i < ordered.length - 1; i++) {
      if (ordered[i] == ordered[i + 1]) continue;
      final pair = '${ordered[i]}_${ordered[i + 1]}';
      if (seen.add(pair)) withBigrams.add(pair);
    }
    return withBigrams;
  }

  String _normalizeToken(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  Map<String, dynamic> _undetermined(
    List<String> tokens, {
    required String language,
    required bool skinOnly,
  }) {
    final present = tokens.toSet();
    late String disease;
    late String severity;
    late double confidence;

    if (skinOnly) {
      disease = 'Not enough recognizable skin symptoms';
      severity = 'Unknown';
      confidence = 0.0;
    } else if (present.isNotEmpty &&
        present.every(
          (t) =>
              _commonRespiratory.contains(t) ||
              t == 'vomiting' ||
              t == 'nausea' ||
              t == 'high_fever' ||
              t == 'mild_fever' ||
              t == 'fever',
        )) {
      disease = 'Possible viral illness';
      severity = present.contains('high_fever') || present.contains('fever')
          ? 'Moderate'
          : 'Low';
      confidence = 0.42;
      return {
        'disease': disease,
        'severity': severity,
        'confidence': confidence,
        'top_predictions': [
          {'disease': disease, 'confidence': confidence, 'severity': severity},
        ],
        'alert_sent': false,
        'source': 'dataset_local',
        'score_type': 'symptom_match_fallback',
        'result_state': 'SUCCESS_FALLBACK',
        'advice': _adviceFor(disease, language: language),
        'disclaimer': _disclaimer(language),
        'language': language.startsWith('hi') ? 'hi' : 'en',
      };
    } else {
      disease = 'Not enough recognizable symptoms';
      severity = 'Unknown';
      confidence = 0.0;
    }

    return {
      'disease': disease,
      'possible_condition': disease,
      'disease_display': disease,
      'severity': severity,
      'confidence': confidence,
      'top_predictions': <Map<String, dynamic>>[],
      'alert_sent': false,
      'source': skinOnly ? 'dataset_skin' : 'dataset_local',
      'score_type': 'symptom_match_fallback',
      'result_state': 'INSUFFICIENT_INPUT',
      'insufficient_symptoms': true,
      'advice':
          'Add more specific symptoms using chips or clearer free-text. '
          'This is not a Low-risk clearance.',
      'disclaimer': _disclaimer(language),
      'message':
          'Screening could not classify reliably from the symptoms provided. '
          'Please add more detail and try again. This is not a diagnosis.',
      'language': language.startsWith('hi') ? 'hi' : 'en',
    };
  }

  String _severityFor(String disease) {
    final lowered = disease.toLowerCase();
    if (_severityCritical.any(lowered.contains)) return 'Critical';
    if (_severityHigh.any(lowered.contains)) return 'High';
    if (_severityModerate.any(lowered.contains)) return 'Moderate';
    return 'Low';
  }

  String _adviceFor(String disease, {required String language}) {
    final hindi = language.startsWith('hi');
    if (disease == 'Undetermined' || disease == 'Possible viral illness') {
      return hindi
          ? 'ये लक्षण आम हैं। आराम करें, तरल पदार्थ लें, और बिगड़ने पर डॉक्टर से मिलें।'
          : 'These symptoms are common. Rest, drink fluids, and consult a doctor if they worsen.';
    }
    return hindi
        ? 'पर्याप्त पानी पिएँ और आराम करें। लक्षणों पर नज़र रखें।'
        : 'Maintain hydration and rest. Monitor symptoms carefully.';
  }

  String _disclaimer(String language) {
    return language.startsWith('hi')
        ? 'यह केवल स्क्रीनिंग सुझाव है, चिकित्सा निदान नहीं।'
        : 'This is a screening suggestion, not a medical diagnosis.';
  }

  String _titleCase(String token) {
    return token
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  double _round3(double value) => (value * 1000).round() / 1000;
}

class SymptomOption {
  const SymptomOption({
    required this.token,
    required this.labelEn,
    required this.labelHi,
  });

  final String token;
  final String labelEn;
  final String labelHi;

  String labelFor(String language) =>
      language.toLowerCase().startsWith('hi') ? labelHi : labelEn;
}

class _DiseaseRow {
  const _DiseaseRow({required this.disease, required this.symptoms});

  final String disease;
  final List<String> symptoms;
}
