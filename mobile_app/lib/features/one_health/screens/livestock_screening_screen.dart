import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/locale_controller.dart';
import '../../../core/sync/offline_api.dart';
import '../../../core/widgets/sync_status_banner.dart';
import '../../../core/widgets/simulate_blackout_button.dart';
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
import '../screening_result_view.dart';

/// Offline-capable livestock symptom screening (One Health).
class LivestockScreeningScreen extends StatefulWidget {
  const LivestockScreeningScreen({super.key});

  @override
  State<LivestockScreeningScreen> createState() => _LivestockScreeningScreenState();
}

class _SignChip {
  final String label;
  final bool dangerous;
  const _SignChip(this.label, {this.dangerous = false});
}

class _BodyArea {
  final String title;
  final IconData icon;
  final List<_SignChip> chips;
  const _BodyArea(this.title, this.icon, this.chips);
}

class _LivestockScreeningScreenState extends State<LivestockScreeningScreen> {
  final _api = ApiService();
  final _offline = OfflineApi.instance;
  final _symptomsCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  String _species = 'CATTLE';
  bool _loading = false;
  Map<String, dynamic>? _result;
  bool _heldInVault = false;
  List<Map<String, dynamic>> _history = [];
  bool _historyLoading = false;
  List<Map<String, dynamic>> _cases = [];
  final Set<String> _selectedSigns = {};

  static const _speciesOptions = [
    ('CATTLE', 'Cattle'),
    ('BUFFALO', 'Buffalo'),
    ('GOAT', 'Goat'),
    ('SHEEP', 'Sheep'),
    ('POULTRY', 'Poultry'),
    ('OTHER', 'Other'),
  ];

  static const _dangerousSigns = <_SignChip>[
    _SignChip('bloody diarrhea', dangerous: true),
    _SignChip('cannot stand', dangerous: true),
    _SignChip('difficulty breathing', dangerous: true),
    _SignChip('gasping', dangerous: true),
    _SignChip('sudden death', dangerous: true),
    _SignChip('collapse', dangerous: true),
  ];

  List<_BodyArea> get _bodyAreas {
    final speciesExtra = switch (_species) {
      'CATTLE' || 'BUFFALO' => const [
          _SignChip('mastitis'),
          _SignChip('swollen udder'),
          _SignChip('clotted milk'),
          _SignChip('milk drop'),
          _SignChip('salivation'),
        ],
      'POULTRY' => const [
          _SignChip('gasping', dangerous: true),
          _SignChip('sudden death', dangerous: true),
          _SignChip('sneezing'),
          _SignChip('ruffled feathers'),
          _SignChip('dead flock', dangerous: true),
        ],
      'GOAT' || 'SHEEP' => const [
          _SignChip('cough'),
          _SignChip('diarrhea'),
          _SignChip('lameness'),
          _SignChip('nasal discharge'),
          _SignChip('itching'),
        ],
      _ => const [
          _SignChip('fever'),
          _SignChip('not eating'),
          _SignChip('weakness'),
        ],
    };

    return [
      _BodyArea('Appetite & energy', Icons.restaurant_outlined, [
        const _SignChip('not eating'),
        const _SignChip('weakness'),
        const _SignChip('lethargy'),
        const _SignChip('fever'),
        const _SignChip('shivering'),
        ...speciesExtra.where((c) =>
            c.label.contains('milk') || c.label == 'ruffled feathers'),
      ]),
      const _BodyArea('Breathing', Icons.air, [
        _SignChip('cough'),
        _SignChip('nasal discharge'),
        _SignChip('sneezing'),
        _SignChip('difficulty breathing', dangerous: true),
        _SignChip('gasping', dangerous: true),
        _SignChip('panting'),
      ]),
      const _BodyArea('Digestion', Icons.water_drop_outlined, [
        _SignChip('diarrhea'),
        _SignChip('bloody diarrhea', dangerous: true),
        _SignChip('loose stool'),
        _SignChip('not drinking'),
      ]),
      _BodyArea('Skin / udder / legs', Icons.pets_outlined, [
        const _SignChip('skin lesions'),
        const _SignChip('itching'),
        const _SignChip('lameness'),
        const _SignChip('limping'),
        const _SignChip('swollen joint'),
        ...speciesExtra.where((c) =>
            c.label.contains('udder') ||
            c.label == 'mastitis' ||
            c.label == 'clotted milk' ||
            c.label == 'salivation'),
      ]),
      const _BodyArea('Dangerous signs', Icons.warning_amber_rounded, _dangerousSigns),
    ];
  }

  List<_SignChip> get _quickSpeciesChips {
    return switch (_species) {
      'CATTLE' || 'BUFFALO' => const [
          _SignChip('fever'),
          _SignChip('not eating'),
          _SignChip('mastitis'),
          _SignChip('milk drop'),
          _SignChip('lameness'),
          _SignChip('diarrhea'),
          _SignChip('difficulty breathing', dangerous: true),
        ],
      'POULTRY' => const [
          _SignChip('gasping', dangerous: true),
          _SignChip('sneezing'),
          _SignChip('diarrhea'),
          _SignChip('not eating'),
          _SignChip('sudden death', dangerous: true),
          _SignChip('ruffled feathers'),
        ],
      'GOAT' || 'SHEEP' => const [
          _SignChip('cough'),
          _SignChip('diarrhea'),
          _SignChip('lameness'),
          _SignChip('fever'),
          _SignChip('not eating'),
          _SignChip('nasal discharge'),
        ],
      _ => const [
          _SignChip('fever'),
          _SignChip('not eating'),
          _SignChip('diarrhea'),
          _SignChip('cough'),
          _SignChip('lameness'),
          _SignChip('difficulty breathing', dangerous: true),
        ],
    };
  }

  @override
  void initState() {
    super.initState();
    _loadCases();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    try {
      final raw = await _offline.get('/one-health/screenings/?domain=ANIMAL');
      final list = raw is List
          ? raw
          : (raw is Map && raw['results'] is List)
              ? raw['results'] as List
              : <dynamic>[];
      if (!mounted) return;
      setState(() {
        _history = list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _historyLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _historyLoading = false);
    }
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

  void _toggleSign(String label) {
    setState(() {
      if (_selectedSigns.contains(label)) {
        _selectedSigns.remove(label);
      } else {
        _selectedSigns.add(label);
      }
      _syncSignsToText();
    });
  }

  void _syncSignsToText() {
    final extra = _symptomsCtrl.text
        .split(RegExp(r'[,;\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && !_isKnownChip(e))
        .toList();
    final combined = [..._selectedSigns, ...extra];
    _symptomsCtrl.text = combined.join(', ');
  }

  bool _isKnownChip(String text) {
    final lower = text.toLowerCase();
    for (final area in _bodyAreas) {
      for (final c in area.chips) {
        if (c.label.toLowerCase() == lower) return true;
      }
    }
    for (final c in _quickSpeciesChips) {
      if (c.label.toLowerCase() == lower) return true;
    }
    return false;
  }

  String get _combinedObservationText {
    final free = _symptomsCtrl.text.trim();
    if (_selectedSigns.isEmpty) return free;
    final parts = <String>{..._selectedSigns};
    for (final p in free.split(RegExp(r'[,;\n]'))) {
      final t = p.trim();
      if (t.isNotEmpty) parts.add(t);
    }
    return parts.join(', ');
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

  void _selectSavedAnimal(Map<String, dynamic> c) {
    setState(() {
      _nameCtrl.text = (c['name'] ?? '').toString();
      final sp = (c['species'] ?? '').toString().toUpperCase();
      if (_speciesOptions.any((o) => o.$1 == sp)) {
        _species = sp;
      }
    });
  }

  Future<void> _analyze() async {
    final text = _combinedObservationText.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tap signs you see, or describe what you observe.'),
        ),
      );
      return;
    }
    setState(() {
      _loading = true;
      _result = null;
      _heldInVault = false;
    });

    final clientId =
        'animal-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
    try {
      await _ensureCase();

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

      try {
        final response = await _api.post(
          '/one-health/animal/analyze/',
          body: {
            'symptoms': text,
            'species': _species,
            'client_id': clientId,
            'language': LocaleController.instance.languageCode,
          },
          timeout: const Duration(seconds: 12),
        );
        if (response is Map && response.isNotEmpty) {
          // Prefer server fields but keep held behaviour
          result = Map<String, dynamic>.from(result);
          if (response['held_in_temp_vault'] == true) {
            result['held_in_temp_vault'] = true;
          }
        }
      } catch (_) {}

      if (!mounted) return;
      // Same as doctor Rx: do NOT show answer yet — TEMP vault until admin restore
      setState(() {
        _result = null;
        _heldInVault = true;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Held in TEMP vault — history fills after admin Restore',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      await _loadHistory();
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
        blob.contains('laboured breathing') ||
        blob.contains('gasping') ||
        blob.contains('respiratory distress') ||
        blob.contains('sudden death') ||
        blob.contains('downer') ||
        blob.contains('paralysis') ||
        blob.contains('collapse') ||
        blob.contains('unconscious') ||
        blob.contains('dead flock') ||
        blob.contains('mass mortality') ||
        (blob.contains('dysentery') || blob.contains('blood stool'));
    final high = (blob.contains('foot') && blob.contains('mouth')) ||
        blob.contains('blister') ||
        blob.contains('vesicle') ||
        blob.contains('mastitis') ||
        blob.contains('swollen udder') ||
        blob.contains('hard udder') ||
        blob.contains('clotted milk') ||
        blob.contains('fever') ||
        blob.contains('high temperature') ||
        blob.contains('hot body') ||
        blob.contains('shivering');
    if (critical &&
        _sevRank('Critical') > _sevRank((ml['severity'] ?? '').toString())) {
      return {
        ...ml,
        'possible_condition': 'Urgent livestock concern (screening)',
        'disease_display': 'Urgent livestock concern (screening)',
        'severity': 'Critical',
        'source': 'rules_boost_ml',
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
    if (blob.contains('bloody') ||
        blob.contains('cannot stand') ||
        blob.contains('difficulty breathing') ||
        blob.contains('gasping') ||
        blob.contains('sudden death') ||
        blob.contains('collapse') ||
        blob.contains('dead flock')) {
      condition = 'Urgent livestock concern (screening)';
      severity = 'Critical';
      advice = 'Isolate animal and contact a veterinary specialist promptly.';
      confidence = 0.8;
    } else if (blob.contains('fever') ||
        blob.contains('mastitis') ||
        blob.contains('swollen udder') ||
        (blob.contains('foot') && blob.contains('mouth')) ||
        blob.contains('blister')) {
      condition = 'Significant livestock signs (screening)';
      severity = 'High';
      advice = 'Isolate if contagious signs. Consult a veterinary specialist today.';
      confidence = 0.7;
    } else if (blob.contains('diarrhea') ||
        blob.contains('cough') ||
        blob.contains('lameness') ||
        blob.contains('not eating') ||
        blob.contains('itching') ||
        blob.contains('skin lesions')) {
      condition = 'Moderate livestock concern (screening)';
      severity = 'Moderate';
      advice =
          'Improve hygiene and hydration. Seek veterinary advice if not improving.';
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
    final finding =
        (r['possible_condition'] ?? r['disease_display'] ?? 'Livestock screening')
            .toString();
    final severity = (r['severity'] ?? 'Low').toString();
    final steps = ScreeningHealthSteps.forResult(
      domain: ScreeningDomain.livestock,
      severity: severity,
      condition: finding,
      symptoms: _combinedObservationText
          .split(RegExp(r'[,;]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    );
    SharedAIHealthChat.open(
      context,
      screeningContext: ScreeningChatContext(
        domain: ScreeningDomain.livestock,
        possibleFinding: finding,
        severity: severity,
        confidence:
            r['confidence'] is num ? (r['confidence'] as num).toDouble() : null,
        advice: r['advice']?.toString() ?? r['message']?.toString(),
        explanation: ScreeningHealthSteps.explanation(
          domain: ScreeningDomain.livestock,
          severity: severity,
          possibleFinding: finding,
        ),
        nextSteps: steps,
        symptoms: [_combinedObservationText.trim()],
        species: _species,
        aiSource: r['source']?.toString(),
        rawResult: Map<String, dynamic>.from(r),
      ),
    );
  }

  void _escalateVet() {
    final r = _result;
    final finding =
        (r?['possible_condition'] ?? 'Livestock screening').toString();
    final severity = (r?['severity'] ?? 'Critical').toString();
    final summary = EscalationPolicy.careTeamSummary(
      domain: ScreeningDomain.livestock,
      possibleFinding: finding,
      severity: severity,
      symptoms: _combinedObservationText.trim(),
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
        title: const Text(
          'Livestock Screening',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: const [
          SimulateBlackoutButton(compact: true),
        ],
      ),
      body: Column(
        children: [
          const SyncStatusBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: SimulateBlackoutButton(),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDBA74)),
                  ),
                  child: Text(
                    ScreeningDisclaimer.enAnimal,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9A3412),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Which animal?',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _speciesOptions.map((s) {
                    final selected = _species == s.$1;
                    return ChoiceChip(
                      label: Text(s.$2),
                      selected: selected,
                      onSelected: (_) => setState(() {
                        _species = s.$1;
                        _selectedSigns.clear();
                        _syncSignsToText();
                      }),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (_cases.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Saved animals',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _cases.map((c) {
                      final name = (c['name'] ?? c['species'] ?? 'Animal').toString();
                      final sp = (c['species'] ?? '').toString();
                      final selected = _nameCtrl.text == (c['name'] ?? '').toString() &&
                          _species == sp.toUpperCase();
                      return ActionChip(
                        avatar: Icon(
                          Icons.pets,
                          size: 16,
                          color: selected
                              ? const Color(0xFFB45309)
                              : const Color(0xFF94A3B8),
                        ),
                        label: Text(
                          sp.isNotEmpty ? '$name ($sp)' : name,
                          style: TextStyle(
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        backgroundColor: selected
                            ? const Color(0xFFFFF7ED)
                            : Colors.white,
                        onPressed: () => _selectSavedAnimal(c),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 20),
                const Text(
                  'Quick signs for this species',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickSpeciesChips.map((c) {
                    final selected = _selectedSigns.contains(c.label);
                    return FilterChip(
                      label: Text(c.label),
                      selected: selected,
                      onSelected: (_) => _toggleSign(c.label),
                      selectedColor: c.dangerous
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFFED7AA),
                      checkmarkColor: c.dangerous
                          ? const Color(0xFFDC2626)
                          : const Color(0xFFB45309),
                      side: c.dangerous
                          ? const BorderSide(color: Color(0xFFFCA5A5))
                          : null,
                      avatar: c.dangerous
                          ? const Icon(
                              Icons.priority_high,
                              size: 16,
                              color: Color(0xFFDC2626),
                            )
                          : null,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Guided check (tap what you see)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 8),
                ..._bodyAreas.map(_buildBodyArea),
                const SizedBox(height: 16),
                TextField(
                  controller: _symptomsCtrl,
                  maxLines: 3,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Anything else?',
                    hintText: 'Add extra details in your own words…',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _analyze,
                    icon: const Icon(Icons.health_and_safety_outlined),
                    label: Text(
                      _loading ? 'Screening…' : 'Run livestock screening',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB45309),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (_heldInVault) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFDBA74)),
                    ),
                    child: const Text(
                      'Held in TEMP vault (admin only).\n'
                      'Answer will appear in Screening history after admin Restore.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9A3412),
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (_result != null) ...[
                  const SizedBox(height: 24),
                  _buildResultCard(_result!),
                ],
                const SizedBox(height: 28),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Screening history',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _historyLoading ? null : _loadHistory,
                      icon: _historyLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, size: 16),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Only released results show here (after admin Restore).',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 10),
                if (_history.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Text(
                      'No released screenings yet.\n'
                      'Run screening → admin Restore → refresh here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B), height: 1.4),
                    ),
                  )
                else
                  ..._history.map((h) {
                    final title =
                        (h['possible_condition'] ?? 'Screening').toString();
                    final sev = (h['severity_level'] ?? '').toString();
                    final advice = (h['advice'] ?? '').toString();
                    final when = (h['created_at'] ?? '').toString();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Severity: $sev',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB45309),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (advice.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              advice,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF475569),
                                height: 1.35,
                              ),
                            ),
                          ],
                          if (when.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              when,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyArea(_BodyArea area) {
    final isDanger = area.title.toLowerCase().contains('dangerous');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDanger ? const Color(0xFFFEF2F2) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDanger ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                area.icon,
                size: 18,
                color: isDanger
                    ? const Color(0xFFDC2626)
                    : const Color(0xFFB45309),
              ),
              const SizedBox(width: 8),
              Text(
                area.title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isDanger
                      ? const Color(0xFF991B1B)
                      : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: area.chips.map((c) {
              final selected = _selectedSigns.contains(c.label);
              return FilterChip(
                label: Text(c.label, style: const TextStyle(fontSize: 12)),
                selected: selected,
                onSelected: (_) => _toggleSign(c.label),
                selectedColor: c.dangerous || isDanger
                    ? const Color(0xFFFEE2E2)
                    : const Color(0xFFFED7AA),
                checkmarkColor: c.dangerous || isDanger
                    ? const Color(0xFFDC2626)
                    : const Color(0xFFB45309),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> r) {
    final severity = (r['severity'] ?? 'Low').toString();
    final finding =
        (r['possible_condition'] ?? r['disease_display'] ?? '—').toString();
    final source = (r['source'] ?? 'on-device').toString();
    final sourceLabel = source.contains('ondevice') || source.contains('mlp')
        ? 'On-device ML'
        : (source.contains('rules') ? 'Rules + ML' : source);
    final conf =
        r['confidence'] is num ? (r['confidence'] as num).toDouble() : null;
    final steps = ScreeningHealthSteps.forResult(
      domain: ScreeningDomain.livestock,
      severity: severity,
      condition: finding,
      symptoms: [_combinedObservationText.trim()],
    );
    final band = EscalationPolicy.normalize(severity);
    final primaryLabel = band == 'Critical'
        ? 'Call Vet Now'
        : 'Contact Veterinary Specialist';

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
      primaryContactLabel: primaryLabel,
      primaryContactIcon: band == 'Critical'
          ? Icons.phone_in_talk_outlined
          : Icons.pets_outlined,
      onContactSecondary: EscalationPolicy.shouldShowEscalationButtons(severity)
          ? () => Navigator.pushNamed(context, AppRoutes.ashaWorkers)
          : null,
      secondaryContactLabel: 'Contact ASHA',
      secondaryContactIcon: Icons.health_and_safety_outlined,
    );
  }
}
