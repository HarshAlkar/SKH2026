import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../../core/security/model_integrity.dart';

/// On-device multi-hot symptom MLP (TFLite) for offline human screening.
class SymptomMlService {
  SymptomMlService._();
  static final SymptomMlService instance = SymptomMlService._();

  static const _modelAsset = 'assets/models/symptom_mlp.tflite';
  static const _labelsAsset = 'assets/models/symptom_labels.json';
  static const missingMessage =
      'Symptom ML model missing. Run: python -m ai_engine.symptoms.train';

  Interpreter? _interpreter;
  List<String> _features = const [];
  List<String> _classes = const [];
  Map<String, String> _severity = const {};
  Map<String, List<String>> _precautions = const {};
  double _temperature = 1.0;
  String? _lastError;
  String _disclaimer =
      'AI-assisted screening only. This result is not a medical diagnosis. '
      'Please consult a qualified healthcare professional.';
  bool _loadAttempted = false;

  String? get lastError => _lastError;
  List<String> get featureVocabulary => List.unmodifiable(_features);
  bool get isReady =>
      _interpreter != null && _features.isNotEmpty && _classes.isNotEmpty;

  static const _aliases = {
    'temp': 'high_fever',
    'temperature': 'high_fever',
    'fever': 'high_fever',
    'rash': 'skin_rash',
    'itch': 'itching',
    'vomit': 'vomiting',
    'tired': 'fatigue',
    'chest': 'chest_pain',
    'breath': 'breathlessness',
    'breathing': 'breathlessness',
    'diarrhea': 'diarrhoea',
    'cold': 'continuous_sneezing',
    'sneeze': 'continuous_sneezing',
  };

  Future<Map<String, dynamic>?> tryPredict(
    List<String> inputs, {
    String language = 'en',
  }) async {
    try {
      return await predict(inputs, language: language);
    } catch (e, st) {
      _lastError = e.toString();
      debugPrint('SymptomMlService.tryPredict failed: $e\n$st');
      return null;
    }
  }

  Future<Map<String, dynamic>> predict(
    List<String> inputs, {
    String language = 'en',
  }) async {
    await _ensureLoaded();
    final interpreter = _interpreter;
    if (interpreter == null || _features.isEmpty || _classes.isEmpty) {
      throw Exception(_lastError ?? missingMessage);
    }

    final tokens = _normalizeInputs(inputs);
    final matchedFeatures = <String>[];
    final vector = Float32List(_features.length);
    for (var i = 0; i < _features.length; i++) {
      if (tokens.contains(_features[i])) {
        vector[i] = 1.0;
        matchedFeatures.add(_features[i]);
      }
    }
    if (matchedFeatures.isEmpty) {
      return {
        'disease': 'Insufficient input',
        'possible_condition': 'Not enough recognizable symptoms',
        'disease_display': 'Not enough recognizable symptoms',
        'severity': 'Unknown',
        'confidence': 0.0,
        'top_predictions': <Map<String, dynamic>>[],
        'matched_features': matchedFeatures,
        'source': 'symptom_mlp_ondevice',
        'score_type': 'model_probability',
        'result_state': 'INSUFFICIENT_INPUT',
        'disclaimer': _disclaimer,
        'message':
            'We could not map enough symptoms to the screening vocabulary. '
            'Please select chips or add more detail. This is not a diagnosis.',
        'insufficient_symptoms': true,
        'language': language,
      };
    }

    final probs = _runInterpreter(interpreter, vector);
    final calibrated = _applyTemperature(probs);
    final ranked = List<int>.generate(calibrated.length, (i) => i)
      ..sort((a, b) => calibrated[b].compareTo(calibrated[a]));

    final top = <Map<String, dynamic>>[];
    final rawTop = <Map<String, dynamic>>[];
    for (final index in ranked.take(5)) {
      if (index >= _classes.length) continue;
      final name = _classes[index];
      final p = calibrated[index];
      final sev = _severity[name] ?? 'Moderate';
      rawTop.add({
        'disease': name,
        'probability': p,
        'confidence': p,
        'severity': sev,
      });
      top.add({
        'disease': name,
        'confidence': _round4(p),
        'probability': _round4(p),
        'severity': sev,
      });
    }

    if (kDebugMode) {
      debugPrint('SymptomMlService inputs=$inputs');
      debugPrint('SymptomMlService normalized=$tokens');
      debugPrint('SymptomMlService matched=$matchedFeatures vectorLen=${vector.length}');
      debugPrint(
        'SymptomMlService top5=${top.map((e) => '${e['disease']}=${e['confidence']}').join(', ')}',
      );
    }

    final best = top.first;
    final maxP = (best['confidence'] as num).toDouble();
    final second = top.length > 1 ? (top[1]['confidence'] as num).toDouble() : 0.0;
    final ambiguous = maxP < 0.45 || (maxP - second) < 0.08;
    final condition = best['disease'].toString();
    final tips = _precautions[condition] ?? const <String>[];

    final headline = ambiguous
        ? 'Elevated-risk screening result'
        : 'Possible condition identified through screening';
    final displayName = ambiguous
        ? 'Elevated-risk screening result'
        : 'Possible: $condition (screening)';

    return {
      'disease': condition,
      'possible_condition': displayName,
      'disease_display': displayName,
      'severity': best['severity'],
      'confidence': best['confidence'],
      'top_predictions': top.take(3).toList(),
      'raw_probabilities': rawTop,
      'matched_features': matchedFeatures,
      'ambiguous': ambiguous,
      'precautions': tips,
      'advice': tips.isEmpty
          ? 'Discuss these screening results with a qualified healthcare professional.'
          : tips.take(3).join('. '),
      'alert_sent': false,
      'source': 'symptom_mlp_ondevice',
      'score_type': 'model_probability',
      'result_state': 'SUCCESS_ONDEVICE_ML',
      'headline': headline,
      'disclaimer': _disclaimer,
      'message': ambiguous
          ? 'Possible conditions to discuss with a healthcare professional are listed below. '
              'AI-assisted screening only. This is not a medical diagnosis.'
          : 'Screening result indicates elevated risk for $condition. '
              'This is not a diagnosis. Please consult a qualified healthcare professional.',
      'language': language,
    };
  }

  List<double> _runInterpreter(Interpreter interpreter, Float32List vector) {
    final inputTensors = interpreter.getInputTensors();
    final outputTensors = interpreter.getOutputTensors();
    if (inputTensors.isEmpty || outputTensors.isEmpty) {
      throw Exception('TFLite model has no input/output tensors');
    }

    final input = [vector];
    final outLen = _classes.isNotEmpty
        ? _classes.length
        : outputTensors.first.numElements as int;
    final output = [Float32List(outLen)];

    try {
      interpreter.run(input, output);
    } catch (e) {
      // Some builds expect nested List shape [1, N].
      final nestedIn = [List<double>.from(vector)];
      final nestedOut = [
        List<double>.filled(_classes.length, 0.0),
      ];
      interpreter.run(nestedIn, nestedOut);
      return _sanitizeProbs(List<double>.from(nestedOut.first));
    }

    return _sanitizeProbs(List<double>.from(output.first));
  }

  List<double> _sanitizeProbs(List<double> raw) {
    var probs = raw.map((v) => v.isFinite ? v.toDouble() : 0.0).toList();
    if (probs.length < _classes.length) {
      probs = [...probs, ...List.filled(_classes.length - probs.length, 0.0)];
    } else if (probs.length > _classes.length) {
      probs = probs.sublist(0, _classes.length);
    }
    final sum = probs.fold<double>(0, (a, b) => a + b);
    if (sum <= 0) {
      return List.filled(probs.length, 1.0 / probs.length);
    }
    // Softmax already applied in Keras; if values are logits or don't sum ~1, renormalize/softmax.
    if ((sum - 1.0).abs() > 0.05) {
      final maxLogit = probs.reduce(math.max);
      final exps = probs.map((p) => math.exp(p - maxLogit)).toList();
      final eSum = exps.fold<double>(0, (a, b) => a + b);
      return exps.map((e) => e / eSum).toList();
    }
    return probs.map((p) => p / sum).toList();
  }

  List<double> _applyTemperature(List<double> probs) {
    if (_temperature <= 0 || (_temperature - 1.0).abs() < 1e-6) {
      return probs;
    }
    // Soften/sharpen: p_i^(1/T) then renormalize (approx for already-softmaxed outputs).
    final t = _temperature;
    final powered = probs.map((p) => math.pow(math.max(p, 1e-12), 1.0 / t).toDouble()).toList();
    final sum = powered.fold<double>(0, (a, b) => a + b);
    return powered.map((p) => p / sum).toList();
  }

  Future<void> _ensureLoaded() async {
    if (_loadAttempted) return;
    _loadAttempted = true;
    try {
      final raw = await rootBundle.loadString(_labelsAsset);
      final labels = jsonDecode(raw) as Map<String, dynamic>;
      _features = (labels['features'] as List).map((e) => e.toString()).toList();
      _classes = (labels['classes'] as List).map((e) => e.toString()).toList();
      _severity = {
        for (final e in ((labels['severity'] as Map?) ?? {}).entries)
          e.key.toString(): e.value.toString(),
      };
      _precautions = {
        for (final e in ((labels['precautions'] as Map?) ?? {}).entries)
          e.key.toString(): ((e.value as List?) ?? const [])
              .map((x) => x.toString())
              .toList(),
      };
      _temperature = (labels['temperature'] is num)
          ? (labels['temperature'] as num).toDouble()
          : 1.0;
      _disclaimer = labels['disclaimer']?.toString() ?? _disclaimer;
    } catch (e) {
      _lastError = 'Failed to load symptom_labels.json: $e';
      debugPrint(_lastError);
      _features = const [];
      _classes = const [];
    }
    try {
      final ok = await ModelIntegrity.verifyAsset(_modelAsset);
      if (!ok) {
        _lastError = 'Model integrity check failed (SHA-256 mismatch).';
        debugPrint(_lastError);
        return;
      }
      _interpreter = await Interpreter.fromAsset(_modelAsset);
      debugPrint(
        'SymptomMlService: loaded TFLite '
        'features=${_features.length} classes=${_classes.length}',
      );
    } catch (e) {
      _lastError = 'Failed to load symptom_mlp.tflite: $e';
      debugPrint(_lastError);
      _interpreter = null;
    }
  }

  /// Public normalize for chips + free-text tokens before building the vector.
  List<String> normalizeInputs(List<String> inputs) => _normalizeInputs(inputs);

  List<String> _normalizeInputs(List<String> inputs) {
    final out = <String>{};
    for (final raw in inputs) {
      final parts = raw
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9_\s]'), ' ')
          .split(RegExp(r'[\s_]+'))
          .where((p) => p.isNotEmpty);
      final list = parts.toList();
      for (var i = 0; i < list.length; i++) {
        final token = list[i];
        out.add(token);
        if (_aliases.containsKey(token)) out.add(_aliases[token]!);
        if (i + 1 < list.length) {
          final pair = '${list[i]}_${list[i + 1]}';
          out.add(pair);
          if (_aliases.containsKey(pair)) out.add(_aliases[pair]!);
        }
      }
      final joined = raw.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '_');
      if (joined.isNotEmpty) out.add(joined);
    }
    return out.toList();
  }

  double _round4(num value) => (value * 10000).round() / 10000;
}
