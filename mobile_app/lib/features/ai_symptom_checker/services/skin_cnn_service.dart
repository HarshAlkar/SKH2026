import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../../core/security/model_integrity.dart';

class SkinCnnService {
  SkinCnnService._();
  static final SkinCnnService instance = SkinCnnService._();

  static const _modelAsset = 'assets/models/skin_cnn.tflite';
  static const _labelsAsset = 'assets/models/skin_labels.json';
  static const missingMessage =
      'Skin CNN is not trained yet. Run: python -m ai_engine.skin.train';

  Interpreter? _interpreter;
  List<String> _codes = const [];
  Map<String, String> _displayNames = const {};
  Map<String, String> _severity = const {};
  int _inputSize = 224;
  String _disclaimer =
      'AI-assisted skin screening only. Screening confidence is not a confirmed diagnosis. '
      'Professional evaluation is recommended.';
  bool _loadAttempted = false;
  bool _loadSucceeded = false;

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
    final condition = best['disease'].toString();
    return {
      'disease': condition,
      'possible_condition': condition,
      'code': best['code'],
      'severity': best['severity'],
      'confidence': best['confidence'],
      'top_predictions': top,
      'alert_sent': false,
      'source': 'skin_cnn_ondevice',
      'disclaimer': _disclaimer,
      'message':
          'AI-assisted skin screening suggests possible elevated risk for $condition. '
          'Screening confidence is not a confirmed diagnosis. '
          'Professional evaluation recommended.',
    };
  }

  Future<void> _ensureLoaded() async {
    if (_loadSucceeded && _interpreter != null) return;
    if (_loadAttempted && _interpreter == null) {
      // Allow one retry after a failed load (e.g. asset race on first open).
      _loadAttempted = false;
    }
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
      _inputSize = int.tryParse('${labels['input_size'] ?? 224}') ?? 224;
    } catch (_) {
      _codes = const [];
    }

    try {
      final ok = await ModelIntegrity.verifyAsset(_modelAsset);
      if (!ok) {
        _interpreter = null;
      } else {
        _interpreter = await Interpreter.fromAsset(_modelAsset);
      }
    } catch (_) {
      try {
        _interpreter = await Interpreter.fromAsset('models/skin_cnn.tflite');
      } catch (_) {
        _interpreter = null;
      }
    }
    _loadSucceeded = _interpreter != null;
  }

  Future<List<List<List<List<double>>>>> _preprocess(File file) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Could not read the selected image.');
    }
    final size = _inputSize;
    final resized = img.copyResize(decoded, width: size, height: size);
    // MobileNetV2/V3 Keras preprocess_input (mode=tf): x/127.5 - 1
    return [
      List.generate(size, (y) {
        return List.generate(size, (x) {
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
