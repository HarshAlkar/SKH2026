import 'escalation_policy.dart';

/// Plain-language recommended next steps (guidance only — never prescriptions).
class ScreeningHealthSteps {
  ScreeningHealthSteps._();

  static List<String> forResult({
    required ScreeningDomain domain,
    required String? severity,
    String? condition,
    List<String> symptoms = const [],
  }) {
    final s = EscalationPolicy.normalize(severity);
    final cond = (condition ?? '').trim().toLowerCase();

    switch (domain) {
      case ScreeningDomain.livestock:
        return _livestock(s, cond);
      case ScreeningDomain.skin:
        return _skin(s, cond);
      case ScreeningDomain.child:
        return _child(s, cond);
      case ScreeningDomain.human:
        return _human(s, cond, symptoms);
    }
  }

  static String explanation({
    required ScreeningDomain domain,
    required String? severity,
    required String possibleFinding,
  }) {
    final s = EscalationPolicy.normalize(severity);
    final finding = possibleFinding.trim().isEmpty
        ? 'an elevated-risk pattern'
        : possibleFinding.trim();
    final prefix = switch (domain) {
      ScreeningDomain.livestock =>
        'Livestock screening suggests a possible concern related to $finding.',
      ScreeningDomain.skin =>
        'AI skin screening suggests a possible finding related to $finding.',
      ScreeningDomain.child =>
        'Developmental screening indicates that further professional assessment may be helpful regarding $finding.',
      ScreeningDomain.human =>
        'AI-assisted screening suggests a possible elevated risk pattern related to $finding.',
    };
    final riskNote = switch (s) {
      'Critical' => ' The risk band is Critical — urgent professional review is recommended.',
      'High' => ' The risk band is High — professional evaluation is recommended.',
      'Moderate' => ' The risk band is Moderate — monitor closely and seek care if it persists or worsens.',
      _ => ' The risk band is Low — basic monitoring is usually appropriate.',
    };
    return '$prefix$riskNote This is AI-assisted screening only, not a diagnosis.';
  }

  static List<String> _human(String s, String cond, List<String> symptoms) {
    final respiratory = _matchesAny(cond, symptoms, const [
      'respir',
      'cough',
      'breath',
      'pneumonia',
      'tb',
      'asthma',
    ]);
    final feverish = _matchesAny(cond, symptoms, const ['fever', 'dengue', 'malaria', 'typhoid']);
    final gi = _matchesAny(cond, symptoms, const ['diarr', 'vomit', 'abdomen', 'gastro', 'stomach']);

    final steps = <String>[];
    if (respiratory) {
      steps.addAll(const [
        'Rest and maintain hydration.',
        'Monitor fever and breathing symptoms.',
        'Avoid close contact if respiratory symptoms worsen.',
      ]);
    } else if (gi) {
      steps.addAll(const [
        'Sip safe fluids often to stay hydrated.',
        'Note stool frequency, vomiting, and dizziness.',
        'Use clean water and careful hand hygiene.',
      ]);
    } else if (feverish) {
      steps.addAll(const [
        'Rest and drink safe fluids.',
        'Monitor temperature and energy levels.',
        'Note any rash, severe headache, or confusion.',
      ]);
    } else {
      steps.addAll(const [
        'Rest and maintain hydration.',
        'Note which symptoms change over the next day.',
        'Avoid self-medicating with leftover prescriptions.',
      ]);
    }

    switch (s) {
      case 'Critical':
        steps.add(
          'Your screening indicates a higher-risk pattern. Please speak with a qualified healthcare professional for proper evaluation now.',
        );
        break;
      case 'High':
        steps.add(
          'Your screening indicates a higher-risk pattern. Please speak with a qualified healthcare professional for proper evaluation.',
        );
        break;
      case 'Moderate':
        steps.add('Seek professional evaluation if symptoms persist or worsen.');
        break;
      default:
        steps.add('Re-check if new symptoms appear or existing ones do not settle.');
    }
    return steps;
  }

  static List<String> _skin(String s, String cond) {
    final steps = <String>[
      'Keep the area clean and dry; avoid scratching or picking.',
      'Note spreading, pain, fever, or discharge over the next 1–2 days.',
      'Protect the area from irritants (harsh soaps, tight clothing).',
    ];
    if (cond.contains('cancer') || cond.contains('melanoma') || s == 'Critical') {
      steps.add(
        'Do not attempt home treatment for suspected serious skin lesions — seek a qualified clinician promptly.',
      );
    } else if (s == 'High') {
      steps.add(
        'Your screening indicates a higher-risk skin pattern. Please speak with a qualified healthcare professional for proper evaluation.',
      );
    } else if (s == 'Moderate') {
      steps.add('If the rash or lesion persists or worsens, consult a doctor or ASHA.');
    } else {
      steps.add('Monitor for a few days; seek care if it spreads or becomes painful.');
    }
    return steps;
  }

  static List<String> _livestock(String s, String cond) {
    final steps = <String>[
      'Ensure clean water and appropriate feed are available.',
      'Isolate the animal from the herd if contagious signs are possible.',
      'Note appetite, breathing, stool, and mobility changes.',
    ];
    switch (s) {
      case 'Critical':
        steps.add(
          'Veterinary attention is urgently recommended. Contact a veterinarian as soon as possible.',
        );
        break;
      case 'High':
        steps.add(
          'Veterinary attention recommended. Arrange assessment soon — do not rely on guesswork treatments.',
        );
        break;
      case 'Moderate':
        steps.add('If signs persist or worsen within 24–48 hours, contact a veterinarian.');
        break;
      default:
        steps.add('Continue basic monitoring; contact a veterinarian if you remain concerned.');
    }
    return steps;
  }

  static List<String> _child(String s, String cond) {
    final steps = <String>[
      'Continue supportive play, talk, and routine feeding at home.',
      'Write down what you observe (eye contact, sitting, walking, words, feeding).',
      'Keep scheduled Anganwadi / PHC / immunization visits.',
    ];
    switch (s) {
      case 'Critical':
      case 'High':
        steps.add(
          'Developmental screening indicates that further professional assessment may be helpful. Please discuss with ASHA or a doctor soon.',
        );
        break;
      case 'Moderate':
        steps.add(
          'Re-check milestones in 2–4 weeks and share concerns with ASHA if they continue.',
        );
        break;
      default:
        steps.add('Keep encouraging age-appropriate activities and ask ASHA if new concerns arise.');
    }
    return steps;
  }

  static bool _matchesAny(String cond, List<String> symptoms, List<String> keys) {
    final blob = ('$cond ${symptoms.join(' ')}').toLowerCase();
    return keys.any(blob.contains);
  }
}
