import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/call_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../chat/widgets/contact_action_row.dart';
import 'escalation_policy.dart';
import 'screening_disclaimer.dart';

/// Optional next-step sheet after High / Critical screening results.
/// Prefer showing the full result screen first; call this only on user action
/// or as a non-blocking follow-up — never as the only view of the result.
Future<void> showEscalationSheet(
  BuildContext context, {
  required String severity,
  required bool isAnimal,
  String language = 'en',
  String? summary,
  bool forceShow = false,
}) async {
  final sev = EscalationPolicy.normalize(severity);
  if (!forceShow && sev != 'High' && sev != 'Critical') return;

  final title = isAnimal
      ? (sev == 'Critical'
          ? 'Urgent veterinary assessment recommended'
          : 'Veterinary attention recommended')
      : (sev == 'Critical'
          ? 'Urgent professional assessment recommended'
          : 'Professional consultation recommended');
  final body = summary?.trim().isNotEmpty == true
      ? summary!.trim()
      : EscalationPolicy.bannerMessage(
          severity: sev,
          domain: isAnimal ? ScreeningDomain.livestock : ScreeningDomain.human,
        );
  final disclaimer =
      ScreeningDisclaimer.text(language: language, isAnimal: isAnimal);
  final doctorFirst = !isAnimal && EscalationPolicy.preferDoctorFirst(sev);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 8),
              Text(
                disclaimer,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF94A3B8),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              if (!isAnimal) ...[
                if (doctorFirst) ...[
                  _EscalationButton(
                    icon: Icons.medical_services_outlined,
                    label: 'Contact Doctor',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(context, AppRoutes.consultDoctor);
                    },
                  ),
                  const SizedBox(height: 10),
                  _EscalationButton(
                    icon: Icons.health_and_safety_outlined,
                    label: 'Contact ASHA',
                    color: const Color(0xFF0F766E),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(context, AppRoutes.ashaWorkers);
                    },
                  ),
                ] else ...[
                  _EscalationButton(
                    icon: Icons.health_and_safety_outlined,
                    label: 'Contact ASHA',
                    color: const Color(0xFF0F766E),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(context, AppRoutes.ashaWorkers);
                    },
                  ),
                  const SizedBox(height: 10),
                  _EscalationButton(
                    icon: Icons.medical_services_outlined,
                    label: 'Contact Doctor',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(context, AppRoutes.consultDoctor);
                    },
                  ),
                ],
                if (sev == 'Critical') ...[
                  const SizedBox(height: 10),
                  _EscalationButton(
                    icon: Icons.emergency_outlined,
                    label: 'Emergency Help',
                    color: const Color(0xFFDC2626),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(context, AppRoutes.emergencyHelp);
                    },
                  ),
                ],
              ] else ...[
                _EscalationButton(
                  icon: Icons.pets_outlined,
                  label: 'Contact Veterinarian',
                  color: const Color(0xFFB45309),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _callFirstVet(context);
                  },
                ),
                const SizedBox(height: 10),
                _EscalationButton(
                  icon: Icons.health_and_safety_outlined,
                  label: 'Contact ASHA Worker',
                  color: const Color(0xFF0F766E),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, AppRoutes.ashaWorkers);
                  },
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Not now'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _callFirstVet(BuildContext context) async {
  try {
    final api = ApiService();
    final raw = await api.get('/one-health/veterinarians/');
    final list = raw is List ? raw : <dynamic>[];
    if (list.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No veterinarian listed yet. Ask ASHA for local AH contacts.',
            ),
          ),
        );
      }
      return;
    }
    final vet = Map<String, dynamic>.from(list.first as Map);
    final userId = parseContactId(vet['user_id']);
    final doctorId = parseContactId(vet['id']);
    if (userId == null || !context.mounted) return;
    await CallLauncher.start(
      context: context,
      peerName: 'Dr. ${vet['full_name'] ?? 'Veterinarian'}',
      receiverUserId: userId.toString(),
      isVideo: true,
      doctorId: doctorId,
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not reach veterinarian list: $e')),
      );
    }
  }
}

class _EscalationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _EscalationButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
