import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/sync/offline_api.dart';
import '../../../core/widgets/sync_status_banner.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_routes.dart';
import '../../ai_health_chat/models/screening_chat_context.dart';
import '../../ai_health_chat/screens/shared_ai_health_chat_screen.dart';
import '../../ai_symptom_checker/services/livestock_ml_service.dart';
import '../escalation_policy.dart';
import '../escalation_sheet.dart';
import '../screening_disclaimer.dart';
import '../screening_health_steps.dart';
import '../screening_persistence.dart';
import '../widgets/screening_result_view.dart';

/// Offline-capable livestock symptom screening (One Health).
class LivestockScreeningScreen extends StatefulWidget {
  const LivestockScreeningScreen({super.key});

  @override
  State<LivestockScreeningScreen> createState() => _LivestockScreeningScreenState();
}

class _LivestockScreeningScreenState extends State<LivestockScreeningScreen> {
  final _api = ApiService();
  final _offline = OfflineApi.instance;
  final _symptomsCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  String _species = 'CATTLE';
  bool _loading = false;
  Map<String, dynamic>? _result;
  List<Map<String, dynamic>> _cases = [];

  static const _speciesOptions = [
    ('CATTLE', 'Cattle'),
    ('BUFFALO', 'Buffalo'),
    ('GOAT', 'Goat'),
    ('SHEEP', 'Sheep'),
    ('POULTRY', 'Poultry'),
    ('OTHER', 'Other'),
  ];

  static const _chipSymptoms = [
    'fever',
    'not eating',
    'diarrhea',
    'cough',
    'lameness',
    'mastitis',
    'nasal discharge',
    'skin lesions',
    'difficulty breathing',
    'bloody diarrhea',
  ];

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  @override
  void dispose() {
    _symptomsCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCases() async {
    try {
      final raw = await _offline.get('/one-health/livestock/');
      if (!mounted) return;
      setState(() {
        _cases = raw is List
            ? raw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
            : [];
      });
    } catch (_) {}
  }

  Future<void> _ensureCase() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    await _offline.post(
      '/one-health/livestock/',
      body: {
        'name': _nameCtrl.text.trim(),
        'species': _species,
        'village': context.read<AuthProvider>().user?.village ?? '',
      },
    );
    await _loadCases();
  }

  Future<void> _analyze() async {
    final text = _symptomsCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Describe what you observe on the animal.')),
      );
      return;
    }
    setState(() {
      _loading = true;
      _result = null;
    });

    final clientId = 'animal-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
    try {
      await _ensureCase();

      // Local-first: TFLite livestock MLP + Critical keyword safety override.
      Map<String, dynamic> result = await LivestockMlService.instance.tryPredict(
            text: text,
            species: _species,
          ) ??
          _localAnimalScreen(text, _species);
      result = _applyCriticalRuleOverride(text, result);

      await ScreeningPersistence.instance.enqueueAnimal(
        inputText: text,
        result: result,
      );

      // Best-effort online path for care-team alerts (High/Critical only via server).
      try {
        final response = await _api.post(
          '/one-health/animal/analyze/',
          body: {
            'symptoms': text,
            'species': _species,
            'client_id': clientId,
            'language': 'en',
          },
          timeout: const Duration(seconds: 12),
        );
        if (response is Map && response.isNotEmpty) {
          final onlineSev = (response['severity'] ?? '').toString();
          if (_sevRank(onlineSev) > _sevRank((result['severity'] ?? '').toString())) {
            result = Map<String, dynamic>.from(response);
            result['source'] = 'server_override_${result['source'] ?? 'ml'}';
          }
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
      // Result-first: do NOT auto-open escalation/chat.
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Screening failed: $e')),
      );
    }
  }

  int _sevRank(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return 3;
      case 'high':
        return 2;
      case 'moderate':
        return 1;
      default:
        return 0;
    }
  }

  Map<String, dynamic> _applyCriticalRuleOverride(
    String text,
    Map<String, dynamic> ml,
  ) {
    final blob = text.toLowerCase();
    final critical = blob.contains('bloody') ||
        blob.contains('cannot stand') ||
        blob.contains('difficulty breathing') ||
        blob.contains('gasping') ||
        blob.contains('sudden death');
    final high = (blob.contains('foot') && blob.contains('mouth')) ||
        blob.contains('mastitis') ||
        blob.contains('fever');
    if (critical && _sevRank('Critical') > _sevRank((ml['severity'] ?? '').toString())) {
      return {
        ...ml,
        'possible_condition': 'Urgent livestock concern (screening)',
        'disease': 'Urgent livestock concern (screening)',
        'severity': 'Critical',
        'confidence': 0.85,
        'advice': 'Isolate animal and contact a veterinarian promptly.',
        'source': 'rules_override_ml',
        'disclaimer': ScreeningDisclaimer.enAnimal,
        'message':
            'Livestock screening indicates elevated risk. '
            'This result is decision support and not a veterinary diagnosis.',
      };
    }
    if (high && _sevRank('High') > _sevRank((ml['severity'] ?? '').toString())) {
      return {
        ...ml,
        'severity': 'High',
        'source': 'rules_boost_ml',
        'disclaimer': ScreeningDisclaimer.enAnimal,
      };
    }
    return ml;
  }

  Map<String, dynamic> _localAnimalScreen(String text, String species) {
    final blob = text.toLowerCase();
    String condition = 'Non-specific livestock signs (screening)';
    String severity = 'Low';
    String advice =
        'Monitor feed, water, and activity. Escalate to a veterinarian if signs worsen.';
    double confidence = 0.35;
    if (blob.contains('bloody') || blob.contains('cannot stand') || blob.contains('breathing')) {
      condition = 'Urgent livestock concern (screening)';
      severity = 'Critical';
      advice = 'Isolate animal and contact a veterinarian promptly.';
      confidence = 0.8;
    } else if (blob.contains('fever') || blob.contains('mastitis') || blob.contains('foot') || blob.contains('mouth')) {
      condition = 'Significant livestock signs (screening)';
      severity = 'High';
      advice = 'Isolate if contagious signs. Consult a veterinarian today.';
      confidence = 0.7;
    } else if (blob.contains('diarrhea') || blob.contains('cough') || blob.contains('lameness')) {
      condition = 'Moderate livestock concern (screening)';
      severity = 'Moderate';
      advice = 'Improve hygiene and hydration. Seek veterinary advice if not improving.';
      confidence = 0.6;
    }
    return {
      'possible_condition': condition,
      'disease_display': condition,
      'severity': severity,
      'confidence': confidence,
      'advice': advice,
      'disclaimer': ScreeningDisclaimer.enAnimal,
      'domain': 'ANIMAL',
      'species': species,
      'source': 'rules_local',
    };
  }

  void _openAiChat() {
    final r = _result;
    if (r == null) return;
    final finding = (r['possible_condition'] ?? r['disease_display'] ?? 'Livestock screening').toString();
    final severity = (r['severity'] ?? 'Low').toString();
    final steps = ScreeningHealthSteps.forResult(
      domain: ScreeningDomain.livestock,
      severity: severity,
      condition: finding,
      symptoms: _symptomsCtrl.text.split(RegExp(r'[,;]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
    );
    SharedAIHealthChat.open(
      context,
      screeningContext: ScreeningChatContext(
        domain: ScreeningDomain.livestock,
        possibleFinding: finding,
        severity: severity,
        confidence: r['confidence'] is num ? (r['confidence'] as num).toDouble() : null,
        advice: r['advice']?.toString() ?? r['message']?.toString(),
        explanation: ScreeningHealthSteps.explanation(
          domain: ScreeningDomain.livestock,
          severity: severity,
          possibleFinding: finding,
        ),
        nextSteps: steps,
        symptoms: [_symptomsCtrl.text.trim()],
        species: _species,
        aiSource: r['source']?.toString(),
        rawResult: Map<String, dynamic>.from(r),
      ),
    );
  }

  void _escalateVet() {
    final r = _result;
    final finding = (r?['possible_condition'] ?? 'Livestock screening').toString();
    final severity = (r?['severity'] ?? 'Critical').toString();
    final summary = EscalationPolicy.careTeamSummary(
      domain: ScreeningDomain.livestock,
      possibleFinding: finding,
      severity: severity,
      symptoms: _symptomsCtrl.text.trim(),
      timestamp: DateTime.now(),
      offlineQueued: r?['queued_offline'] == true,
      aiSource: r?['source']?.toString(),
    );
    showEscalationSheet(
      context,
      severity: severity,
      isAnimal: true,
      summary: summary,
      forceShow: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Livestock Screening', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Column(
        children: [
          const SyncStatusBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDBA74)),
                  ),
                  child: Text(
                    ScreeningDisclaimer.enAnimal,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF9A3412), height: 1.4),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Species', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _speciesOptions.map((s) {
                    final selected = _species == s.$1;
                    return ChoiceChip(
                      label: Text(s.$2),
                      selected: selected,
                      onSelected: (_) => setState(() => _species = s.$1),
                      selectedColor: const Color(0xFFFDBA74),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Animal name / tag (optional)',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (_cases.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Saved animals: ${_cases.map((c) => c['name'] ?? c['species']).join(', ')}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _symptomsCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Observed signs',
                    hintText: 'e.g. fever, not eating, diarrhea, lameness…',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _chipSymptoms.map((s) {
                    return ActionChip(
                      label: Text(s),
                      onPressed: () {
                        final cur = _symptomsCtrl.text.trim();
                        _symptomsCtrl.text = cur.isEmpty ? s : '$cur, $s';
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _analyze,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB45309),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Run livestock screening', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                if (_result != null) ...[
                  const SizedBox(height: 24),
                  _buildResultCard(_result!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> r) {
    final severity = (r['severity'] ?? 'Low').toString();
    final finding = (r['possible_condition'] ?? r['disease_display'] ?? '—').toString();
    final source = (r['source'] ?? 'on-device').toString();
    final sourceLabel = source.contains('ondevice') || source.contains('mlp')
        ? 'On-device ML'
        : (source.contains('rules') ? 'Rules + ML' : source);
    final conf = r['confidence'] is num ? (r['confidence'] as num).toDouble() : null;
    final steps = ScreeningHealthSteps.forResult(
      domain: ScreeningDomain.livestock,
      severity: severity,
      condition: finding,
      symptoms: [_symptomsCtrl.text.trim()],
    );

    return ScreeningResultView(
      domain: ScreeningDomain.livestock,
      title: 'LIVESTOCK SCREENING RESULT',
      possibleFinding: finding,
      severity: severity,
      confidence: conf,
      aiSourceLabel: 'AI source: $sourceLabel',
      explanation: ScreeningHealthSteps.explanation(
        domain: ScreeningDomain.livestock,
        severity: severity,
        possibleFinding: finding,
      ),
      nextSteps: steps,
      whenToSeekHelp: EscalationPolicy.whenToSeekHelp(
        severity: severity,
        domain: ScreeningDomain.livestock,
      ),
      disclaimer: (r['disclaimer'] ?? ScreeningDisclaimer.enAnimal).toString(),
      queuedOffline: r['queued_offline'] == true,
      onAskAi: _openAiChat,
      onContactPrimary: EscalationPolicy.shouldShowEscalationButtons(severity)
          ? _escalateVet
          : null,
      primaryContactLabel: 'Contact Veterinarian',
      primaryContactIcon: Icons.pets_outlined,
      onContactSecondary: EscalationPolicy.shouldShowEscalationButtons(severity)
          ? () => Navigator.pushNamed(context, AppRoutes.ashaWorkers)
          : null,
      secondaryContactLabel: 'Contact ASHA',
      secondaryContactIcon: Icons.health_and_safety_outlined,
    );
  }
}
