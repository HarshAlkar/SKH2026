import '../../one_health/escalation_policy.dart';

/// Context payload passed into SharedAIHealthChat.
class ScreeningChatContext {
  final ScreeningDomain domain;
  final String possibleFinding;
  final String severity;
  final double? confidence;
  final String? advice;
  final String? explanation;
  final List<String> nextSteps;
  final List<String> symptoms;
  final String? species;
  final String? aiSource;
  final Map<String, dynamic> rawResult;
  final int? childAgeMonths;

  const ScreeningChatContext({
    required this.domain,
    required this.possibleFinding,
    required this.severity,
    this.confidence,
    this.advice,
    this.explanation,
    this.nextSteps = const [],
    this.symptoms = const [],
    this.species,
    this.aiSource,
    this.rawResult = const {},
    this.childAgeMonths,
  });

  String get domainLabel => switch (domain) {
        ScreeningDomain.human => 'human symptom screening',
        ScreeningDomain.skin => 'skin screening',
        ScreeningDomain.livestock => 'livestock / veterinary screening',
        ScreeningDomain.child => 'child development screening',
      };

  String toPromptBlock() {
    final buf = StringBuffer()
      ..writeln('Domain: $domainLabel')
      ..writeln('Possible finding (screening): $possibleFinding')
      ..writeln('Risk level: ${EscalationPolicy.normalize(severity)}');
    if (confidence != null) {
      buf.writeln('Confidence: ${(confidence! * 100).toStringAsFixed(1)}%');
    }
    if (species != null && species!.isNotEmpty) {
      buf.writeln('Animal species: $species');
    }
    if (childAgeMonths != null) {
      buf.writeln('Child age (months): $childAgeMonths');
    }
    if (symptoms.isNotEmpty) {
      buf.writeln('Symptoms / observations: ${symptoms.join(', ')}');
    }
    if (aiSource != null && aiSource!.isNotEmpty) {
      buf.writeln('AI source: $aiSource');
    }
    if (explanation != null && explanation!.isNotEmpty) {
      buf.writeln('Explanation shown to user: $explanation');
    }
    if (nextSteps.isNotEmpty) {
      buf.writeln('Recommended next steps already shown:');
      for (final s in nextSteps) {
        buf.writeln('- $s');
      }
    }
    if (advice != null && advice!.isNotEmpty) {
      buf.writeln('Advice field: $advice');
    }
    return buf.toString();
  }
}
