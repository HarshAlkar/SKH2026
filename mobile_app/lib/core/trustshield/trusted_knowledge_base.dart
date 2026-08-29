import 'dart:convert';

import 'package:flutter/services.dart';

import 'trustshield_models.dart';

/// Local curated KB — source of truth for offline / fail-safe verification.
class TrustedKnowledgeBase {
  static final TrustedKnowledgeBase instance = TrustedKnowledgeBase._();
  TrustedKnowledgeBase._();

  Map<String, dynamic>? _kb;

  Future<Map<String, dynamic>> load({bool force = false}) async {
    if (!force && _kb != null) return _kb!;
    final raw =
        await rootBundle.loadString('assets/trustshield/curated_claims.json');
    _kb = jsonDecode(raw) as Map<String, dynamic>;
    return _kb!;
  }

  Future<HealthClaimResult> verifyLocal(String claim) async {
    // Always reload curated JSON so asset updates apply after hot restart.
    final kb = await load(force: true);
    var text = claim.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    text = text
        .replaceAll('drinkin ', 'drinking ')
        .replaceAll('drinkin', 'drinking')
        .replaceAll('drinkingwater', 'drinking water')
        .replaceAll('goodfor', 'good for');
    final now = DateTime.now().toUtc().toIso8601String();
    const disclaimer =
        'AI-assisted verification only. This is not a medical diagnosis. '
        'VitalReach does not claim 100% certainty. Consult a qualified healthcare professional.';

    if (text.isEmpty) {
      return HealthClaimResult.fromJson({
        'claim': '',
        'status': 'UNVERIFIED',
        'riskLevel': 'LOW',
        'confidence': 0,
        'explanation': 'No claim text was provided.',
        'recommendedAction':
            'Paste a WhatsApp or community health message to verify.',
        'sources': [],
        'verifiedAt': now,
        'disclaimer': disclaimer,
        'offline': true,
        'kbLabel': '${kb['label'] ?? ''}',
      });
    }

    for (final entry in (kb['entries'] as List? ?? [])) {
      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);
      final groups = (map['keyword_groups'] as List? ?? [])
          .map((g) => (g as List).map((e) => '$e'.toLowerCase()).toList())
          .toList();
      var ok = groups.isNotEmpty;
      for (final group in groups) {
        if (!group.any((token) => text.contains(token))) {
          ok = false;
          break;
        }
      }
      if (!ok) {
        final keywords =
            (map['keywords'] as List? ?? []).map((e) => '$e'.toLowerCase());
        final hits = keywords.where((k) => text.contains(k)).length;
        ok = hits >= 2;
      }
      if (!ok) continue;

      return HealthClaimResult.fromJson({
        'claim': map['claim_normalized'] ?? claim,
        'status': map['status'] ?? 'UNVERIFIED',
        'riskLevel': map['riskLevel'] ?? 'LOW',
        'confidence': map['confidence'] ?? 0.8,
        'explanation': map['explanation'] ?? '',
        'recommendedAction': map['recommendedAction'] ?? '',
        'sources': map['sources'] ?? [],
        'verifiedAt': now,
        'disclaimer': disclaimer,
        'offline': true,
        'correctedGuidance': map['correctedGuidance'] ?? '',
        'kbLabel': kb['label'] ?? '',
      });
    }

    return HealthClaimResult.fromJson({
      'claim': claim.trim(),
      'status': 'UNVERIFIED',
      'riskLevel': 'MODERATE',
      'confidence': 0.35,
      'explanation':
          'VitalReach could not find enough trusted evidence in the local curated knowledge base to verify this claim.',
      'recommendedAction':
          'Do not act on this message as medical advice. Consult a qualified healthcare professional if concerned.',
      'sources': [
        {
          'name': 'VitalReach local verified database',
          'type': 'LOCAL_VERIFIED_DATABASE',
          'reference': 'local://trustshield/no_match',
        }
      ],
      'verifiedAt': now,
      'disclaimer': disclaimer,
      'offline': true,
      'correctedGuidance':
          'Health information check from VitalReach:\n\nWe could not verify this forwarded health message against trusted information.\nPlease do not self-medicate based on unverified claims.\nConsult a qualified healthcare professional when needed.',
      'kbLabel': kb['label'] ?? '',
    });
  }
}
