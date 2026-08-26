import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class SkinCnnService {
  SkinCnnService._();
  static final SkinCnnService instance = SkinCnnService._();

  static const _modelAsset = 'assets/models/skin_cnn.tflite';
  static const _labelsAsset = 'assets/models/skin_labels.json';
  static const missingMessage =
      'Skin CNN is not trained yet. Run: python -m ai_engine.skin.train --data-dir ai_engine/data/ham10000';

  Interpreter? _interpreter;
  List<String> _codes = const [];
  Map<String, String> _displayNames = const {};
  Map<String, String> _severity = const {};
  String _disclaimer =
      'Screening suggestion only, not a medical diagnosis. HAM10000-style models are biased toward lighter skin tones.';
  bool _loadAttempted = false;

  Future<Map<String, dynamic>?> tryPredict(File imageFile) async {
    try {
      return await predict(imageFile);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> predict(File imageFile) async {
    await _ensureLoaded();
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw Exception(missingMessage);
    }

    final input = await _preprocess(imageFile);
    final output = List.generate(1, (_) => List.filled(math.max(_codes.length, 7), 0.0));
    interpreter.run(input, output);
    final probs = output.first;
    final ranked = List<int>.generate(probs.length, (i) => i)
      ..sort((a, b) => probs[b].compareTo(probs[a]));

    final top = <Map<String, dynamic>>[];
    for (final index in ranked.take(3)) {
      if (index >= _codes.length) continue;
      final code = _codes[index];
      top.add({
        'code': code,
        'disease': _displayNames[code] ?? code,
        'confidence': _round3(probs[index]),
        'severity': _severity[code] ?? 'Moderate',
      });
    }
    if (top.isEmpty) {
      throw Exception('Skin CNN returned an empty prediction.');
    }
    final best = top.first;
    return {
      'disease': best['disease'],
      'code': best['code'],
      'severity': best['severity'],
      'confidence': best['confidence'],
      'top_predictions': top,
      'alert_sent': false,
      'source': 'skin_cnn_ondevice',
      'disclaimer': _disclaimer,
    };
  }

  Future<void> _ensureLoaded() async {
    if (_loadAttempted) return;
    _loadAttempted = true;
    try {
      final raw = await rootBundle.loadString(_labelsAsset);
      final labels = jsonDecode(raw) as Map<String, dynamic>;
      _codes = (labels['classes'] as List).map((e) => e.toString()).toList();
      _displayNames = {
        for (final entry in ((labels['display_names'] as Map?) ?? {}).entries)
          entry.key.toString(): entry.value.toString(),
      };
      _severity = {
        for (final entry in ((labels['severity'] as Map?) ?? {}).entries)
          entry.key.toString(): entry.value.toString(),
      };
      _disclaimer = labels['disclaimer']?.toString() ?? _disclaimer;
    } catch (_) {
      _codes = const ['akiec', 'bcc', 'bkl', 'df', 'nv', 'mel', 'vasc'];
    }

    try {
      _interpreter = await Interpreter.fromAsset(_modelAsset);
    } catch (_) {
      try {
        _interpreter = await Interpreter.fromAsset('models/skin_cnn.tflite');
      } catch (_) {
        _interpreter = null;
      }
    }
  }

  Future<List<List<List<List<double>>>>> _preprocess(File file) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Could not read the selected image.');
    }
    final resized = img.copyResize(decoded, width: 224, height: 224);
    return [
      List.generate(224, (y) {
        return List.generate(224, (x) {
          final pixel = resized.getPixel(x, y);
          return [
            (pixel.r.toDouble() / 127.5) - 1.0,
            (pixel.g.toDouble() / 127.5) - 1.0,
            (pixel.b.toDouble() / 127.5) - 1.0,
          ];
        });
      }),
    ];
  }

  double _round3(num value) => (value * 1000).round() / 1000;
}
