import '../services/api_service.dart';
import '../services/locale_controller.dart';
import '../services/connectivity_service.dart';
import '../sync/local_store.dart';
import '../sync/offline_api.dart';
import 'trusted_knowledge_base.dart';
import 'trustshield_models.dart';

/// Health claim verifier — curated KB is source of truth; API optional.
class HealthClaimVerifier {
  static final HealthClaimVerifier instance = HealthClaimVerifier._();
  HealthClaimVerifier._();

  final _api = ApiService();
  final _kb = TrustedKnowledgeBase.instance;
  final _store = LocalStore.instance;
  final _connectivity = ConnectivityService();

  /// Detect rough "forwarded health claim" intent for routing into TrustShield.
  bool looksLikeHealthClaim(String text) {
    final t = text.toLowerCase();
    const cues = [
      'whatsapp',
      'cure',
      'antibiotic',
      'antibiotics',
      'treatment',
      'guaranteed',
      'dengue',
      'diabetes',
      'forwarded',
      'doctor said',
      'scheme',
      'ors',
      'vaccine',
    ];
    return cues.any(t.contains);
  }

  Future<HealthClaimResult> verify(String claim) async {
    final trimmed = claim.trim();
    if (trimmed.isEmpty) {
      return _kb.verifyLocal('');
    }

    final online = await _connectivity.isConnected();
    if (!online) {
      final local = await _kb.verifyLocal(trimmed);
      await _cacheResult(local);
      return local;
    }

    try {
      final raw = await _api.post(
        '/trustshield/verify/',
        body: {
          'claim': trimmed,
          'context': 'healthcare',
          'language': LocaleController.instance.languageCode,
        },
        timeout: const Duration(seconds: 12),
      );
      if (raw is Map) {
        final result =
            HealthClaimResult.fromJson(Map<String, dynamic>.from(raw));
        // Never accept VERIFIED without sources from server/KB
        if (result.status == ClaimStatus.verified && result.sources.isEmpty) {
          return _kb.verifyLocal(trimmed);
        }
        await _cacheResult(result);
        return result;
      }
    } catch (_) {
      // Fail safe to local curated KB — never invent VERIFIED online
    }

    final local = await _kb.verifyLocal(trimmed);
    await _cacheResult(local);
    return local;
  }

  Future<void> reportMisinformation(HealthClaimResult result) async {
    final body = {
      'claim': result.claim,
      'status': result.statusLabel,
      'riskLevel': result.riskLevel.name.toUpperCase(),
      'explanation': result.explanation,
    };
    try {
      final online = await _connectivity.isConnected();
      if (online) {
        await _api.post('/trustshield/report/', body: body);
        return;
      }
    } catch (_) {}
    await OfflineApi.instance.post('/trustshield/report/', body: body);
  }

  Future<void> _cacheResult(HealthClaimResult result) async {
    try {
      await _store.putCache(
        'trustshield_last_result',
        result.toJson(),
      );
    } catch (_) {}
  }
}
