import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/trustshield/trustshield_models.dart';
import '../../../core/trustshield/trustshield_service.dart';
import '../../../core/widgets/sync_status_banner.dart';
import '../../../routes/app_routes.dart';
import '../../../l10n/l10n.dart';

/// TrustShield — Verify Health Information (Bad Reading challenge).
class VerifyHealthInformationScreen extends StatefulWidget {
  const VerifyHealthInformationScreen({super.key});

  @override
  State<VerifyHealthInformationScreen> createState() =>
      _VerifyHealthInformationScreenState();
}

class _VerifyHealthInformationScreenState
    extends State<VerifyHealthInformationScreen> {
  final _controller = TextEditingController();
  final _verifier = HealthClaimVerifier.instance;

  bool _checking = false;
  int _step = 0;
  HealthClaimResult? _result;
  String? _error;

  static const _demos = [
    'WhatsApp says antibiotics cure dengue in two days.',
    'Drinking a particular household substance is a guaranteed cure for diabetes.',
    'DRINKIN WATER IS GOOD FOR HEALTH',
    'Washing hands with soap helps reduce infection risk.',
    'A rare mineral tea reverses all heart disease overnight without doctors.',
    'Give antibiotics immediately to all cattle if milk drop starts.',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _checking = true;
      _step = 0;
      _result = null;
      _error = null;
    });

    try {
      setState(() => _step = 1);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      setState(() => _step = 2);
      final result = await _verifier.verify(_controller.text);
      if (!mounted) return;
      setState(() {
        _step = 3;
        _result = result;
        _checking = false;
      });
      setState(() => _step = 4);
    } catch (e) {
      if (!mounted) return;
      // Fail safe: local unverified path already inside verifier; surface only hard errors
      setState(() {
        _checking = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _shareGuidance() async {
    final r = _result;
    if (r == null) return;
    final text = r.correctedGuidance.isNotEmpty
        ? r.correctedGuidance
        : 'Health information check from VitalReach:\n\n'
            'Status: ${r.statusLabel}\n'
            '${r.explanation}\n\n'
            '${r.recommendedAction}\n\n'
            '${r.disclaimer}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Corrected guidance copied — paste into WhatsApp.'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  Future<void> _report() async {
    final r = _result;
    if (r == null) return;
    try {
      await _verifier.reportMisinformation(r);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Misinformation report saved (syncs when online).'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          context.l10n.verifyHealthInfo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
                const Text(
                  'VitalReach TrustShield',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Check a forwarded health message before acting on it.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Paste a WhatsApp message or health claim...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _demos
                      .map(
                        (d) => ActionChip(
                          label: Text(
                            d.length > 36 ? '${d.substring(0, 36)}…' : d,
                            style: const TextStyle(fontSize: 11),
                          ),
                          onPressed: () {
                            _controller.text = d;
                            setState(() {});
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _checking ? null : _check,
                    icon: _checking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.verified_user_outlined),
                    label: Text(
                      _checking ? 'Checking…' : 'Check Claim',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (_checking || _step > 0) ...[
                  const SizedBox(height: 20),
                  _ProgressSteps(step: _step, checking: _checking),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                if (_result != null) ...[
                  const SizedBox(height: 20),
                  _TrustResultCard(
                    result: _result!,
                    onShare: _shareGuidance,
                    onReport: _report,
                    onAskDoctor: () =>
                        Navigator.pushNamed(context, AppRoutes.consultDoctor),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSteps extends StatelessWidget {
  const _ProgressSteps({required this.step, required this.checking});

  final int step;
  final bool checking;

  @override
  Widget build(BuildContext context) {
    final items = [
      'Claim identified',
      'Risk assessed',
      'Trusted information checked',
      'Verification completed',
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            checking ? 'Checking health claim…' : 'Verification pipeline',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 10),
          ...List.generate(items.length, (i) {
            final done = step > i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    done ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 18,
                    color: done
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    items[i],
                    style: TextStyle(
                      fontSize: 13,
                      color: done
                          ? const Color(0xFF166534)
                          : const Color(0xFF64748B),
                      fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TrustResultCard extends StatelessWidget {
  const _TrustResultCard({
    required this.result,
    required this.onShare,
    required this.onReport,
    required this.onAskDoctor,
  });

  final HealthClaimResult result;
  final VoidCallback onShare;
  final VoidCallback onReport;
  final VoidCallback onAskDoctor;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(result);
    final title = _titleFor(result);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconFor(result), color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          if (result.offline) ...[
            const SizedBox(height: 8),
            const Text(
              'Offline verification — using locally verified information.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB45309),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _kv('Claim', result.claim),
          _kv('Assessment', result.statusLabel),
          _kv(
            'Risk',
            result.riskLevel.name.toUpperCase(),
          ),
          _kv(
            'Confidence',
            '${(result.confidence * 100).round()}% (model match — not certainty)',
          ),
          const SizedBox(height: 8),
          const Text('Why', style: TextStyle(fontWeight: FontWeight.w700)),
          Text(result.explanation, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 8),
          const Text(
            'Recommended action',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(result.recommendedAction, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 12),
          const Text('Evidence', style: TextStyle(fontWeight: FontWeight.w700)),
          ...result.sources.map(
            (s) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '✓ ${s.name} (${s.type})',
                style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
              ),
            ),
          ),
          if (result.kbLabel.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Dataset: ${result.kbLabel}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
          if (result.verifiedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Verified: ${result.verifiedAt!.toLocal()}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            result.disclaimer,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => _showEvidence(context),
                child: const Text('View Evidence'),
              ),
              OutlinedButton(
                onPressed: onAskDoctor,
                child: const Text('Ask Doctor'),
              ),
              if (result.correctedGuidance.isNotEmpty || result.isDangerous)
                ElevatedButton(
                  onPressed: onShare,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Share Corrected Guidance'),
                ),
              TextButton(
                onPressed: onReport,
                child: const Text('Report Misinformation'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEvidence(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Evidence / sources',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Trusted source (curated) — not AI-invented facts.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            ...result.sources.map(
              (s) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(s.name),
                subtitle: Text('${s.type}\n${s.reference}'),
                isThreeLine: true,
              ),
            ),
            if (result.correctedGuidance.isNotEmpty) ...[
              const Divider(),
              const Text(
                'Corrected guidance',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              SelectableText(result.correctedGuidance),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: result.correctedGuidance),
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Color(0xFF0F172A), height: 1.35),
          children: [
            TextSpan(
              text: '$k: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: v),
          ],
        ),
      ),
    );
  }

  static Color _colorFor(HealthClaimResult r) {
    if (r.status == ClaimStatus.verified) return const Color(0xFF15803D);
    if (r.riskLevel == RiskLevel.high ||
        r.riskLevel == RiskLevel.critical ||
        r.status == ClaimStatus.highRisk) {
      return const Color(0xFFB91C1C);
    }
    if (r.status == ClaimStatus.misleading) return const Color(0xFFC2410C);
    return const Color(0xFFB45309);
  }

  static IconData _iconFor(HealthClaimResult r) {
    if (r.status == ClaimStatus.verified) return Icons.verified_outlined;
    if (r.isDangerous) return Icons.warning_amber_rounded;
    return Icons.help_outline;
  }

  static String _titleFor(HealthClaimResult r) {
    if (r.status == ClaimStatus.verified) {
      return 'VERIFIED AGAINST TRUSTED INFORMATION';
    }
    if (r.riskLevel == RiskLevel.high || r.status == ClaimStatus.highRisk) {
      return 'HIGH-RISK MISINFORMATION';
    }
    if (r.status == ClaimStatus.misleading) {
      return 'MISLEADING HEALTH CLAIM';
    }
    return 'UNVERIFIED HEALTH CLAIM';
  }
}
