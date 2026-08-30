import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';
import '../../ai_health_chat/models/screening_chat_context.dart';
import '../../ai_health_chat/screens/shared_ai_health_chat_screen.dart';
import '../escalation_policy.dart';
import '../escalation_sheet.dart';
import '../screening_disclaimer.dart';
import '../screening_health_steps.dart';
import '../screening_persistence.dart';
import '../screening_result_view.dart';

/// Rule-based childhood milestone / growth screening (not a diagnosis).
class ChildDevelopmentScreen extends StatefulWidget {
  const ChildDevelopmentScreen({super.key});

  @override
  State<ChildDevelopmentScreen> createState() => _ChildDevelopmentScreenState();
}

class _ChildDevelopmentScreenState extends State<ChildDevelopmentScreen> {
  int _ageMonths = 12;
  final _weightCtrl = TextEditingController();
  final Set<String> _concerns = {};
  Map<String, dynamic>? _result;

  static const _concernOptions = [
    ('not_sitting', 'Not sitting without support (by ~9 mo)'),
    ('no_words', 'No words / babble delay'),
    ('not_walking', 'Not walking (by ~18 mo)'),
    ('poor_eye', 'Poor eye contact / social response'),
    ('feeding', 'Feeding difficulty / poor weight gain'),
    ('feverish', 'Frequent illness / lethargy'),
  ];

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _runScreen() async {
    final hits = _concerns.length;
    String severity = 'Low';
    String condition = 'Age-appropriate monitoring (screening)';
    String advice =
        'Continue routine check-ups at the PHC. This tool only flags concerns for discussion with a health worker.';

    if (_concerns.contains('poor_eye') ||
        (_concerns.contains('not_walking') && _ageMonths >= 18)) {
      severity = 'High';
      condition =
          'Developmental concern — further professional assessment may be helpful (screening)';
      advice =
          'Discuss with ASHA / paediatric clinician soon. This is not a developmental diagnosis.';
    } else if (hits >= 2 || _concerns.contains('feeding')) {
      severity = 'Moderate';
      condition = 'Growth / milestone follow-up suggested (screening)';
      advice = 'Share observations with ASHA or doctor at next visit. Track weight monthly.';
    } else if (hits == 1) {
      severity = 'Moderate';
      condition = 'Single milestone concern (screening)';
      advice = 'Re-check in 2–4 weeks. Escalate if more delays appear.';
    }

    final weight = double.tryParse(_weightCtrl.text.trim());
    if (weight != null && _ageMonths >= 6 && weight < 5.5) {
      severity = severity == 'Low' ? 'Moderate' : severity;
      if (severity == 'Moderate' && hits >= 1) severity = 'High';
      condition = 'Possible undernutrition concern (screening)';
      advice =
          'Confirm weight at Anganwadi / PHC. Seek advice on feeding. Not a nutritional diagnosis.';
    }

    final result = {
      'possible_condition': condition,
      'severity': severity,
      'advice': advice,
      'disclaimer': ScreeningDisclaimer.enHuman,
      'source': 'child_rules',
      'age_months': _ageMonths,
      'concerns': _concerns.toList(),
    };

    setState(() => _result = result);

    // Persist for care-team sync (same Offline pathway as other screenings).
    try {
      await ScreeningPersistence.instance.enqueueHuman(
        inputType: 'child_development',
        result: {
          ...result,
          'disease': condition,
          'message': advice,
        },
        inputText:
            'age_months=$_ageMonths; concerns=${_concerns.join(',')}; weight=${_weightCtrl.text.trim()}',
      );
    } catch (_) {}

    // Result-first: do NOT auto-open escalation sheet.
  }

  void _openAiChat() {
    final r = _result;
    if (r == null) return;
    final finding = r['possible_condition'].toString();
    final severity = r['severity'].toString();
    final steps = ScreeningHealthSteps.forResult(
      domain: ScreeningDomain.child,
      severity: severity,
      condition: finding,
      symptoms: _concerns.toList(),
    );
    SharedAIHealthChat.open(
      context,
      screeningContext: ScreeningChatContext(
        domain: ScreeningDomain.child,
        possibleFinding: finding,
        severity: severity,
        advice: r['advice']?.toString(),
        explanation: ScreeningHealthSteps.explanation(
          domain: ScreeningDomain.child,
          severity: severity,
          possibleFinding: finding,
        ),
        nextSteps: steps,
        symptoms: _concerns.toList(),
        aiSource: 'child_rules',
        rawResult: Map<String, dynamic>.from(r),
        childAgeMonths: _ageMonths,
      ),
    );
  }

  void _escalate() {
    final r = _result;
    final finding = (r?['possible_condition'] ?? 'Child development screening').toString();
    final severity = (r?['severity'] ?? 'High').toString();
    final summary = EscalationPolicy.careTeamSummary(
      domain: ScreeningDomain.child,
      possibleFinding: finding,
      severity: severity,
      symptoms: 'age $_ageMonths mo; ${_concerns.join(', ')}',
      timestamp: DateTime.now(),
      offlineQueued: true,
      aiSource: 'child_rules',
    );
    showEscalationSheet(
      context,
      severity: severity,
      isAnimal: false,
      summary: summary,
      forceShow: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Child development check', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              ScreeningDisclaimer.enHuman,
              style: const TextStyle(fontSize: 13, color: Color(0xFF065F46), height: 1.4),
            ),
          ),
          const SizedBox(height: 20),
          Text('Age: $_ageMonths months', style: const TextStyle(fontWeight: FontWeight.w600)),
          Slider(
            value: _ageMonths.toDouble(),
            min: 1,
            max: 60,
            divisions: 59,
            label: '$_ageMonths mo',
            onChanged: (v) => setState(() => _ageMonths = v.round()),
          ),
          TextField(
            controller: _weightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Weight (kg, optional)',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Concerns (tap all that apply)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._concernOptions.map((c) {
            final selected = _concerns.contains(c.$1);
            return CheckboxListTile(
              value: selected,
              title: Text(c.$2, style: const TextStyle(fontSize: 14)),
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _concerns.add(c.$1);
                  } else {
                    _concerns.remove(c.$1);
                  }
                });
              },
            );
          }),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _runScreen,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Run screening', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 20),
            _buildResultCard(_result!),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> r) {
    final severity = r['severity'].toString();
    final finding = r['possible_condition'].toString();
    final steps = ScreeningHealthSteps.forResult(
      domain: ScreeningDomain.child,
      severity: severity,
      condition: finding,
      symptoms: _concerns.toList(),
    );
    final band = EscalationPolicy.normalize(severity);
    final doctorFirst = EscalationPolicy.preferDoctorFirst(band);

    return ScreeningResultView(
      domain: ScreeningDomain.child,
      title: 'CHILD DEVELOPMENT SCREENING',
      possibleFinding: finding,
      severity: severity,
      aiSourceLabel: 'AI source: Rule-based screening',
      explanation: ScreeningHealthSteps.explanation(
        domain: ScreeningDomain.child,
        severity: severity,
        possibleFinding: finding,
      ),
      nextSteps: steps,
      whenToSeekHelp: EscalationPolicy.whenToSeekHelp(
        severity: severity,
        domain: ScreeningDomain.child,
      ),
      disclaimer: ScreeningDisclaimer.enHuman,
      onAskAi: _openAiChat,
      onContactPrimary: EscalationPolicy.shouldShowEscalationButtons(band)
          ? _escalate
          : null,
      primaryContactLabel: doctorFirst ? 'Contact Doctor' : 'Contact ASHA',
      secondaryContactLabel: doctorFirst ? 'Contact ASHA' : 'Contact Doctor',
      primaryContactIcon: doctorFirst
          ? Icons.medical_services_outlined
          : Icons.health_and_safety_outlined,
      secondaryContactIcon: doctorFirst
          ? Icons.health_and_safety_outlined
          : Icons.medical_services_outlined,
      onContactSecondary: EscalationPolicy.shouldShowEscalationButtons(band)
          ? () {
              if (doctorFirst) {
                Navigator.pushNamed(context, AppRoutes.ashaWorkers);
              } else {
                Navigator.pushNamed(context, AppRoutes.consultDoctor);
              }
            }
          : null,
    );
  }
}
