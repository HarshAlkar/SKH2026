import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../../core/security/model_integrity.dart';

/// On-device livestock condition-family MLP for offline One Health screening.
class LivestockMlService {
  LivestockMlService._();
  static final LivestockMlService instance = LivestockMlService._();

  static const _modelAsset = 'assets/models/livestock_mlp.tflite';
  static const _labelsAsset = 'assets/models/livestock_labels.json';

  Interpreter? _interpreter;
  List<String> _features = const [];
  List<String> _classes = const [];
  List<String> _species = const [];
  List<String> _binaryCols = const [];
  Map<String, String> _severity = const {};
  Map<String, String> _displayNames = const {};
  String _disclaimer =
      'Livestock screening indicates decision support only and is not a veterinary diagnosis. '
      'Consult a qualified veterinarian.';
  bool _loadAttempted = false;

  Future<Map<String, dynamic>?> tryPredict({
    required String text,
    required String species,
  }) async {
    try {
      return await predict(text: text, species: species);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> predict({
    required String text,
    required String species,
  }) async {
    await _ensureLoaded();
    final interpreter = _interpreter;
    if (interpreter == null || _features.isEmpty) {
      throw Exception('Livestock ML model not loaded');
    }

    final flags = _textFlags(text);
    final vector = _buildVector(species, flags);
    final input = [vector];
    final output = List.generate(1, (_) => List.filled(_classes.length, 0.0));
    interpreter.run(input, output);
    final probs = output.first;
    final ranked = List<int>.generate(probs.length, (i) => i)
      ..sort((a, b) => probs[b].compareTo(probs[a]));

    final top = <Map<String, dynamic>>[];
    for (final index in ranked.take(3)) {
      if (index >= _classes.length) continue;
      final family = _classes[index];
      final name = _displayNames[family] ?? family;
      top.add({
        'family': family,
        'disease': name,
        'condition': name,
        'confidence': _round3(probs[index]),
        'severity': _severity[family] ?? 'Moderate',
      });
    }
    final best = top.first;
    final condition = best['condition'].toString();
    final severity = best['severity'].toString();
    return {
      'possible_condition': condition,
      'disease': condition,
      'disease_display': condition,
      'family': best['family'],
      'severity': severity,
      'confidence': best['confidence'],
      'top_predictions': top,
      'advice': _adviceFor(severity),
      'disclaimer': _disclaimer,
      'domain': 'ANIMAL',
      'species': species,
      'source': 'livestock_mlp_ondevice',
      'message':
          'Livestock screening indicates elevated risk for $condition. '
          'This result is decision support and not a veterinary diagnosis. '
          'Consult a qualified veterinarian.',
    };
  }

  String _adviceFor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return 'Isolate animal if possible and contact a veterinarian urgently.';
      case 'high':
        return 'Contact a veterinarian promptly. Monitor appetite, breathing, and hydration.';
      case 'moderate':
        return 'Improve husbandry (shade, water, hygiene). Seek vet advice if worsening.';
      default:
        return 'Continue monitoring. Consult a veterinarian if new signs appear.';
    }
  }

  Map<String, bool> _textFlags(String text) {
    final t = text.toLowerCase();
    return {
      'Appetite_Loss':
          t.contains('not eating') || t.contains('off feed') || t.contains('appetite'),
      'Vomiting': t.contains('vomit'),
      'Diarrhea':
          t.contains('diarrhea') || t.contains('diarrhoea') || t.contains('scours'),
      'Coughing': t.contains('cough'),
      'Labored_Breathing':
          t.contains('breath') || t.contains('panting') || t.contains('gasping'),
      'Lameness': t.contains('lame') || t.contains('limp') || t.contains('hoof'),
      'Skin_Lesions':
          t.contains('skin') || t.contains('mange') || t.contains('lesion'),
      'Nasal_Discharge': t.contains('nasal') || t.contains('runny nose'),
      'Eye_Discharge': t.contains('eye') && t.contains('discharge'),
    };
  }

  List<double> _buildVector(String species, Map<String, bool> flags) {
    final mapped = _mapSpecies(species);
    final speciesOh = _species.map((s) => s.toLowerCase() == mapped ? 1.0 : 0.0);
    final binaries = _binaryCols.map((c) => (flags[c] ?? false) ? 1.0 : 0.0);
    // age/weight/temp/hr unknown on free-text path → zeros
    return [...speciesOh, ...binaries, 0.0, 0.0, 0.0, 0.0];
  }

  String _mapSpecies(String species) {
    switch (species.toUpperCase()) {
      case 'CATTLE':
      case 'BUFFALO':
        return 'cow';
      case 'GOAT':
        return 'goat';
      case 'SHEEP':
        return 'sheep';
      case 'POULTRY':
        return 'pig';
      default:
        return 'dog';
    }
  }

  Future<void> _ensureLoaded() async {
    if (_loadAttempted) return;
    _loadAttempted = true;
    try {
      final raw = await rootBundle.loadString(_labelsAsset);
      final labels = jsonDecode(raw) as Map<String, dynamic>;
      _features = (labels['features'] as List).map((e) => e.toString()).toList();
      _classes = (labels['classes'] as List).map((e) => e.toString()).toList();
      _species = ((labels['species'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList();
      _binaryCols = ((labels['binary_cols'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList();
      _severity = {
        for (final e in ((labels['severity'] as Map?) ?? {}).entries)
          e.key.toString(): e.value.toString(),
      };
      _displayNames = {
        for (final e in ((labels['display_names'] as Map?) ?? {}).entries)
          e.key.toString(): e.value.toString(),
      };
      _disclaimer = labels['disclaimer']?.toString() ?? _disclaimer;
    } catch (_) {}
    try {
      final ok = await ModelIntegrity.verifyAsset(_modelAsset);
      if (!ok) {
        _interpreter = null;
      } else {
        _interpreter = await Interpreter.fromAsset(_modelAsset);
      }
    } catch (_) {
      _interpreter = null;
    }
  }

  double _round3(num value) => (value * 1000).round() / 1000;
}
