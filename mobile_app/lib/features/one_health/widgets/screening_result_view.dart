import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../escalation_policy.dart';
import '../screening_disclaimer.dart';
import '../screening_health_steps.dart';

/// Consistent screening result layout across human / skin / livestock / child.
class ScreeningResultView extends StatelessWidget {
  final ScreeningDomain domain;
  final String title;
  final String possibleFinding;
  final String severity;
  final double? confidence;
  final bool confidenceIsFallback;
  final String? aiSourceLabel;
  final String? explanation;
  final List<String> nextSteps;
  final String? whenToSeekHelp;
  final String? disclaimer;
  final bool queuedOffline;
  final List<Widget>? extraTop;
  final VoidCallback? onAskAi;
  final VoidCallback? onContactPrimary;
  final VoidCallback? onContactSecondary;
  final String? primaryContactLabel;
  final String? secondaryContactLabel;
  final IconData? primaryContactIcon;
  final IconData? secondaryContactIcon;

  const ScreeningResultView({
    super.key,
    required this.domain,
    this.title = 'SCREENING RESULT',
    required this.possibleFinding,
    required this.severity,
    this.confidence,
    this.confidenceIsFallback = false,
    this.aiSourceLabel,
    this.explanation,
    this.nextSteps = const [],
    this.whenToSeekHelp,
    this.disclaimer,
    this.queuedOffline = false,
    this.extraTop,
    this.onAskAi,
    this.onContactPrimary,
    this.onContactSecondary,
    this.primaryContactLabel,
    this.secondaryContactLabel,
    this.primaryContactIcon,
    this.secondaryContactIcon,
  });

  Color get _bandColor {
    switch (EscalationPolicy.normalize(severity)) {
      case 'Critical':
        return const Color(0xFFDC2626);
      case 'High':
        return const Color(0xFFEA580C);
      case 'Moderate':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF059669);
    }
  }

  @override
  Widget build(BuildContext context) {
    final band = EscalationPolicy.normalize(severity);
    final showEscalate = EscalationPolicy.shouldShowEscalationButtons(band);
    final meaning = explanation ??
        ScreeningHealthSteps.explanation(
          domain: domain,
          severity: band,
          possibleFinding: possibleFinding,
        );
    final steps = nextSteps.isNotEmpty
        ? nextSteps
        : ScreeningHealthSteps.forResult(
            domain: domain,
            severity: band,
            condition: possibleFinding,
          );
    final seek = whenToSeekHelp ??
        EscalationPolicy.whenToSeekHelp(severity: band, domain: domain);
    final disc = disclaimer ??
        ScreeningDisclaimer.text(
          language: 'en',
          isAnimal: domain == ScreeningDomain.livestock,
        );
    final banner = EscalationPolicy.bannerMessage(severity: band, domain: domain);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _bandColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              if (aiSourceLabel != null && aiSourceLabel!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F1FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    aiSourceLabel!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ScreeningDisclaimer.possibleConditionLabel('en'),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            possibleFinding,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _bandColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Risk: ${band.toUpperCase()}',
              style: TextStyle(
                color: _bandColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          if (confidence != null && confidence! > 0 && !confidenceIsFallback) ...[
            const SizedBox(height: 10),
            Text(
              'Confidence: ${(confidence! * 100).clamp(0, 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (confidenceIsFallback) ...[
            const SizedBox(height: 10),
            Text(
              'Fallback screening score — not model probabilities',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
          if (extraTop != null) ...extraTop!,
          if (band == 'High' || band == 'Critical') ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _bandColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _bandColor.withValues(alpha: 0.35)),
              ),
              child: Text(
                banner,
                style: TextStyle(
                  color: _bandColor,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  fontSize: 13,
                ),
              ),
            ),
          ] else if (band == 'Moderate') ...[
            const SizedBox(height: 14),
            Text(
              banner,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            'What this means',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            meaning,
            style: TextStyle(color: Colors.grey.shade700, height: 1.45, fontSize: 14),
          ),
          const SizedBox(height: 18),
          const Text(
            'Recommended next steps',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: TextStyle(color: Colors.grey.shade700)),
                  Expanded(
                    child: Text(
                      step,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.4,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'When to seek professional help',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            seek,
            style: TextStyle(color: Colors.grey.shade700, height: 1.45, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Text(
            disc,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontStyle: FontStyle.italic,
              height: 1.35,
            ),
          ),
          if (queuedOffline) ...[
            const SizedBox(height: 8),
            const Text(
              'Saved offline — will sync when internet returns.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (onAskAi != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: onAskAi,
                icon: const Icon(Icons.smart_toy_outlined),
                label: const Text('Ask AI about this'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          if (showEscalate && onContactPrimary != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onContactPrimary,
                icon: Icon(primaryContactIcon ?? Icons.medical_services_outlined),
                label: Text(primaryContactLabel ?? 'Contact professional'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _bandColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          if (showEscalate && onContactSecondary != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: onContactSecondary,
                icon: Icon(secondaryContactIcon ?? Icons.health_and_safety_outlined),
                label: Text(secondaryContactLabel ?? 'Contact support'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F766E),
                  side: const BorderSide(color: Color(0xFF0F766E)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
