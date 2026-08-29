import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../security/model_integrity.dart';
import '../services/locale_controller.dart';

/// Detects English / Hindi / Marathi from typed text.
///
/// Uses a hashed char-n-gram linear model (JSON weights, optional TFLite)
/// trained from the Kaggle Indian Language Identification set, plus a
/// Devanagari lexicon fallback for Hindi vs Marathi.
class LanguageIdService {
  LanguageIdService._();
  static final LanguageIdService instance = LanguageIdService._();

  static const _labelsAsset = 'assets/models/langid_labels.json';
  static const _modelAsset = 'assets/models/langid.tflite';
  static const threshold = 0.7;

  Interpreter? _interpreter;
  List<String> _classes = const ['en', 'hi', 'mr'];
  int _dim = 256;
  int _nMin = 2;
  int _nMax = 4;
  List<List<double>> _coef = const [];
  List<double> _intercept = const [];
  Map<String, List<String>> _lexicon = const {};
  bool _loadAttempted = false;

  Future<void> ensureLoaded() async {
    if (_loadAttempted) return;
    _loadAttempted = true;
    try {
      final raw = await rootBundle.loadString(_labelsAsset);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _classes = (json['classes'] as List).map((e) => e.toString()).toList();
      _dim = (json['dim'] as num?)?.toInt() ?? 256;
      _nMin = (json['n_min'] as num?)?.toInt() ?? 2;
      _nMax = (json['n_max'] as num?)?.toInt() ?? 4;
      _coef = [
        for (final row in (json['coef'] as List? ?? const []))
          [for (final v in (row as List)) (v as num).toDouble()],
      ];
      _intercept = [
        for (final v in (json['intercept'] as List? ?? const []))
          (v as num).toDouble(),
      ];
      final lex = json['lexicon'];
      if (lex is Map) {
        _lexicon = {
          for (final e in lex.entries)
            e.key.toString(): [
              for (final w in (e.value as List? ?? const [])) w.toString(),
            ],
        };
      }
    } catch (e) {
      debugPrint('LanguageIdService labels missing: $e');
    }
    try {
      final ok = await ModelIntegrity.verifyAsset(_modelAsset);
      if (ok) {
        _interpreter = await Interpreter.fromAsset(_modelAsset);
      }
    } catch (e) {
      debugPrint('LanguageIdService TFLite optional skip: $e');
      _interpreter = null;
    }
  }

  /// Detect language of [text]. Returns en/hi/mr.
  /// If confidence is below [threshold], [fallback] (Settings locale) is used.
  Future<String> detect(String text, {String? fallback}) async {
    await ensureLoaded();
    final fb = fallback ?? LocaleController.instance.languageCode;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return fb;

    final script = _scriptHint(trimmed);
    if (script == 'en') return 'en';

    final lexicon = _lexiconScore(trimmed);
    final model = _modelProbs(trimmed);
    String best = fb;
    var conf = 0.0;
    if (model != null) {
      var maxI = 0;
      for (var i = 1; i < model.length; i++) {
        if (model[i] > model[maxI]) maxI = i;
      }
      best = maxI < _classes.length ? _classes[maxI] : fb;
      conf = model[maxI];
    }
    if (lexicon != null && (model == null || conf < 0.85)) {
      if (lexicon.$2 >= 2 && lexicon.$2 > (lexicon.$3)) {
        best = lexicon.$1;
        conf = math.max(conf, 0.75);
      }
    }
    if (script == 'deva' && best == 'en') {
      best = lexicon?.$1 ?? fb;
    }
    if (conf < threshold && lexicon == null && model == null) {
      return fb;
    }
    if (conf < threshold && best != fb && lexicon == null) {
      return fb;
    }
    return best;
  }

  String? _scriptHint(String text) {
    var latin = 0;
    var deva = 0;
    for (final unit in text.runes) {
      if ((unit >= 0x41 && unit <= 0x5A) || (unit >= 0x61 && unit <= 0x7A)) {
        latin++;
      } else if (unit >= 0x0900 && unit <= 0x097F) {
        deva++;
      }
    }
    if (deva == 0 && latin >= 8) return 'en';
    if (deva >= 4) return 'deva';
    return null;
  }

  (String, int, int)? _lexiconScore(String text) {
    var hi = 0;
    var mr = 0;
    for (final w in _lexicon['hi'] ?? const <String>[]) {
      if (w.isNotEmpty && text.contains(w)) hi++;
    }
    for (final w in _lexicon['mr'] ?? const <String>[]) {
      if (w.isNotEmpty && text.contains(w)) mr++;
    }
    // Built-in distinctive tokens even if labels JSON missing.
    const hiExtra = ['है', 'हैं', 'आप', 'नहीं', 'कैसे', 'मुझे'];
    const mrExtra = ['आहे', 'आहेत', 'तुम्ही', 'नाही', 'कसे', 'मला'];
    for (final w in hiExtra) {
      if (text.contains(w)) hi++;
    }
    for (final w in mrExtra) {
      if (text.contains(w)) mr++;
    }
    if (hi == 0 && mr == 0) return null;
    if (mr > hi) return ('mr', mr, hi);
    if (hi > mr) return ('hi', hi, mr);
    return null;
  }

  List<double>? _modelProbs(String text) {
    final vec = _vectorize(text);
    if (_interpreter != null && _classes.isNotEmpty) {
      try {
        final output = [List<double>.filled(_classes.length, 0.0)];
        _interpreter!.run([vec], output);
        return List<double>.from(output.first);
      } catch (e) {
        debugPrint('LanguageIdService tflite run failed: $e');
      }
    }
    if (_coef.length == _classes.length && _coef.first.length == _dim) {
      final logits = List<double>.generate(_classes.length, (i) {
        var s = i < _intercept.length ? _intercept[i] : 0.0;
        final row = _coef[i];
        for (var j = 0; j < _dim; j++) {
          s += row[j] * vec[j];
        }
        return s;
      });
      return _softmax(logits);
    }
    return null;
  }

  Float32List _vectorize(String text) {
    final vec = Float32List(_dim);
    final compact = text.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    if (compact.isEmpty) return vec;
    for (var n = _nMin; n <= _nMax; n++) {
      if (compact.length < n) continue;
      for (var i = 0; i <= compact.length - n; i++) {
        final gram = compact.substring(i, i + n);
        vec[_fnv1a(gram) % _dim] += 1.0;
      }
    }
    var sum = 0.0;
    for (final v in vec) {
      sum += v;
    }
    if (sum > 0) {
      for (var i = 0; i < vec.length; i++) {
        vec[i] /= sum;
      }
    }
    return vec;
  }

  int _fnv1a(String text) {
    var h = 2166136261;
    for (final unit in text.codeUnits) {
      h ^= unit;
      h = (h * 16777619) & 0xFFFFFFFF;
    }
    return h;
  }

  List<double> _softmax(List<double> logits) {
    final max = logits.reduce(math.max);
    final exps = logits.map((v) => math.exp(v - max)).toList();
    final sum = exps.fold<double>(0, (a, b) => a + b);
    return exps.map((v) => v / sum).toList();
  }
}
