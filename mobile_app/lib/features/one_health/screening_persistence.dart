import 'dart:math';

import '../../../core/sync/offline_api.dart';

/// Persist screening events locally first, sync via OfflineApi when online.
class ScreeningPersistence {
  ScreeningPersistence._();
  static final ScreeningPersistence instance = ScreeningPersistence._();

  final OfflineApi _offline = OfflineApi.instance;

  Future<void> enqueueHuman({
    required String inputType,
    required String inputText,
    required Map<String, dynamic> result,
  }) async {
    final clientId =
        'human-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
    final condition = (result['disease'] ??
            result['possible_condition'] ??
            'Undetermined')
        .toString();
    final severity = (result['severity'] ?? 'Low').toString();
    final confidence = result['confidence'];
    await _offline.post(
      '/one-health/screenings/',
      body: {
        'domain': 'HUMAN',
        'input_type': inputType,
        'input_text': inputText,
        'possible_condition': condition,
        'severity_level': severity,
        'confidence': confidence is num ? confidence : 0,
        'advice': (result['advice'] ?? result['message'] ?? '').toString(),
        'result_json': {
          ...result,
          'client_id': clientId,
        },
        'client_id': clientId,
      },
    );
    result['queued_offline'] = true;
    result['client_id'] = clientId;
  }

  Future<void> enqueueAnimal({
    required String inputText,
    required Map<String, dynamic> result,
    String? livestockCaseId,
  }) async {
    final clientId =
        'animal-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
    await _offline.post(
      '/one-health/screenings/',
      body: {
        'domain': 'ANIMAL',
        'input_type': 'symptoms',
        'input_text': inputText,
        'possible_condition':
            (result['possible_condition'] ?? result['disease'] ?? '').toString(),
        'severity_level': (result['severity'] ?? 'Low').toString(),
        'confidence': result['confidence'] is num ? result['confidence'] : 0,
        'advice': (result['advice'] ?? result['message'] ?? '').toString(),
        'result_json': {...result, 'client_id': clientId},
        'client_id': clientId,
        if (livestockCaseId != null) 'livestock_case': livestockCaseId,
      },
    );
    result['queued_offline'] = true;
    result['client_id'] = clientId;
  }
}
