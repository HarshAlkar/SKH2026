/// Shared risk bands and escalation copy for One Health screening.
enum ScreeningDomain { human, skin, livestock, child }

class EscalationPolicy {
  EscalationPolicy._();

  static String normalize(String? severity) {
    final s = (severity ?? 'Low').trim().toLowerCase();
    if (s == 'critical') return 'Critical';
    if (s == 'high') return 'High';
    if (s == 'moderate') return 'Moderate';
    if (s == 'unknown' || s == 'unavailable' || s == 'n/a') return 'Unknown';
    return 'Low';
  }

  static bool shouldShowEscalationButtons(String? severity) {
    final s = normalize(severity);
    return s == 'High' || s == 'Critical';
  }

  /// Prefer doctor first for Critical; ASHA first for High (human/child/skin).
  static bool preferDoctorFirst(String? severity) {
    return normalize(severity) == 'Critical';
  }

  /// Farmer-facing severity labels for livestock (internal band unchanged).
  static String farmerFacingLabel(String? severity) {
    switch (normalize(severity)) {
      case 'Critical':
        return 'Urgent — call vet now';
      case 'High':
        return 'See a vet today';
      case 'Moderate':
        return 'Keep a close watch';
      case 'Unknown':
        return 'Screening incomplete';
      default:
        return 'Watch & care';
    }
  }

  /// Short action line under the severity meter (livestock).
  static String farmerFacingAction(String? severity) {
    switch (normalize(severity)) {
      case 'Critical':
        return 'Immediate veterinary help recommended. Isolate if contagious signs are present.';
      case 'High':
        return 'Contact a veterinary specialist today. Do not wait for signs to worsen.';
      case 'Moderate':
        return 'Re-check in 24–48 hours. Call a vet sooner if the animal worsens.';
      case 'Unknown':
        return 'Add clearer signs and try again, or ask a veterinarian if you are worried.';
      default:
        return 'Monitor feed, water, and activity. Seek advice if new signs appear.';
    }
  }

  static String displaySeverityLabel({
    required String? severity,
    required ScreeningDomain domain,
  }) {
    final band = normalize(severity);
    if (domain == ScreeningDomain.livestock) {
      return farmerFacingLabel(band);
    }
    return 'Risk: ${band.toUpperCase()}';
  }

  static String bannerMessage({
    required String? severity,
    required ScreeningDomain domain,
  }) {
    final s = normalize(severity);
    final isAnimal = domain == ScreeningDomain.livestock;
    switch (s) {
      case 'Critical':
        return isAnimal
            ? 'Urgent — call a veterinary specialist now. Isolate the animal if contagious signs are present.'
            : 'Urgent professional assessment recommended. Contact a qualified healthcare professional promptly.';
      case 'High':
        return isAnimal
            ? 'See a veterinary specialist today. Speak with a qualified veterinarian soon.'
            : 'Professional consultation recommended. Please speak with a qualified healthcare professional.';
      case 'Moderate':
        return isAnimal
            ? 'Keep a close watch. Consult a veterinarian if signs persist or worsen within 24–48 hours.'
            : 'Consider consulting a healthcare professional if symptoms persist or worsen.';
      default:
        return isAnimal
            ? 'Watch & care — continue monitoring the animal. Seek veterinary advice if new or worsening signs appear.'
            : 'Continue monitoring. Seek professional advice if symptoms persist or worsen.';
    }
  }

  static String whenToSeekHelp({
    required String? severity,
    required ScreeningDomain domain,
  }) {
    final s = normalize(severity);
    final isAnimal = domain == ScreeningDomain.livestock;
    final isChild = domain == ScreeningDomain.child;
    switch (s) {
      case 'Critical':
        return isAnimal
            ? 'Call a veterinary specialist as soon as possible. Isolate the animal if contagious signs are present.'
            : (isChild
                ? 'Seek paediatric / PHC evaluation promptly. Contact ASHA if you need help reaching care.'
                : 'Seek qualified healthcare evaluation promptly. Use emergency services if the person is severely unwell.');
      case 'High':
        return isAnimal
            ? 'Arrange veterinary evaluation today. Do not wait for signs to worsen.'
            : (isChild
                ? 'Discuss this screening with ASHA, Anganwadi, or a doctor soon for proper assessment.'
                : 'Arrange consultation with a doctor or ASHA soon for proper evaluation.');
      case 'Moderate':
        return isAnimal
            ? 'Contact a veterinarian if signs do not improve within 24–48 hours or if the animal worsens.'
            : (isChild
                ? 'Share observations with ASHA or at the next PHC / Anganwadi visit. Re-check if concerns grow.'
                : 'Consult a healthcare professional if symptoms persist beyond a few days or worsen.');
      default:
        return isAnimal
            ? 'Routine monitoring is usually enough. Contact a veterinarian if you remain concerned.'
            : (isChild
                ? 'Continue routine check-ups. Ask ASHA if you have new developmental concerns.'
                : 'Routine self-care and monitoring is usually enough. Seek care if you remain concerned.');
    }
  }

  /// Concise care-team summary (not a diagnosis).
  static String careTeamSummary({
    required ScreeningDomain domain,
    required String possibleFinding,
    required String severity,
    required String symptoms,
    required DateTime timestamp,
    required bool offlineQueued,
    String? aiSource,
  }) {
    final band = normalize(severity).toUpperCase();
    final domainLabel = switch (domain) {
      ScreeningDomain.livestock => 'Livestock',
      ScreeningDomain.skin => 'Skin',
      ScreeningDomain.child => 'Child development',
      ScreeningDomain.human => 'Human symptom',
    };
    final lines = <String>[
      'VitalReach screening indicates a $band-RISK pattern ($domainLabel).',
      if (symptoms.trim().isNotEmpty) 'Symptoms / observations: ${symptoms.trim()}.',
      'AI screening result: possible elevated risk for $possibleFinding.',
      'Source: ${aiSource ?? 'on-device screening'}.',
      'Timestamp: ${timestamp.toIso8601String()}.',
      'Connectivity: ${offlineQueued ? 'saved offline (will sync)' : 'online / synced when available'}.',
      'Professional evaluation recommended. This is not a confirmed diagnosis.',
    ];
    return lines.join('\n');
  }
}
