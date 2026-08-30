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
  String? bookingSymptoms,
  bool forceShow = false,
}) async {
  final sev = EscalationPolicy.normalize(severity);
  if (!forceShow && sev != 'High' && sev != 'Critical') return;

  final title = isAnimal
      ? (sev == 'Critical'
          ? 'Urgent — Call Veterinary Specialist'
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
  final notes = (bookingSymptoms ?? '').trim();

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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isAnimal && sev == 'Critical'
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
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
                    icon: Icons.event_available,
                    label: 'Book Doctor',
                    color: const Color(0xFF0F766E),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(
                        context,
                        AppRoutes.bookAppointment,
                        arguments: {
                          if (notes.isNotEmpty) 'symptoms': notes,
                        },
                      );
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
                    icon: Icons.event_available,
                    label: 'Book Doctor',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(
                        context,
                        AppRoutes.bookAppointment,
                        arguments: {
                          if (notes.isNotEmpty) 'symptoms': notes,
                        },
                      );
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
                  icon: sev == 'Critical'
                      ? Icons.phone_in_talk_outlined
                      : Icons.pets_outlined,
                  label: sev == 'Critical'
                      ? 'Call Veterinary Specialist'
                      : 'Contact Veterinary Specialist',
                  color: sev == 'Critical'
                      ? const Color(0xFFDC2626)
                      : const Color(0xFFB45309),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await showVeterinarianPicker(context);
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

/// Lists veterinarians from `/one-health/veterinarians/` and starts a call.
Future<void> showVeterinarianPicker(BuildContext context) async {
  List<Map<String, dynamic>> vets = [];
  String? loadError;
  try {
    final api = ApiService();
    final raw = await api.get('/one-health/veterinarians/');
    final list = raw is List ? raw : <dynamic>[];
    vets = list
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
      ..sort((a, b) {
        final aAvail = a['is_available'] == true ? 0 : 1;
        final bAvail = b['is_available'] == true ? 0 : 1;
        return aAvail.compareTo(bAvail);
      });
  } catch (e) {
    loadError = e.toString();
  }

  if (!context.mounted) return;

  if (loadError != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not reach veterinarian list: $loadError')),
    );
    return;
  }

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
              const Text(
                'Choose Veterinary Specialist',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Available specialists are listed first. Tap to start a video consult.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              if (vets.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDBA74)),
                  ),
                  child: const Text(
                    'No veterinarian listed yet. Ask ASHA for local animal husbandry contacts, or try again later.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9A3412),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, AppRoutes.ashaWorkers);
                  },
                  icon: const Icon(Icons.health_and_safety_outlined),
                  label: const Text('Contact ASHA'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await showVeterinarianPicker(context);
                  },
                  child: const Text('Retry'),
                ),
              ] else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: vets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final vet = vets[i];
                      final name =
                          (vet['full_name'] ?? vet['name'] ?? 'Veterinarian')
                              .toString();
                      final spec =
                          (vet['specialization'] ?? 'Veterinary Specialist')
                              .toString();
                      final hospital =
                          (vet['hospital_name'] ?? '').toString();
                      final available = vet['is_available'] == true;
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            Navigator.pop(ctx);
                            await _callVet(context, vet);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: available
                                    ? const Color(0xFFFDBA74)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: available
                                      ? const Color(0xFFFFF7ED)
                                      : const Color(0xFFF1F5F9),
                                  child: Icon(
                                    Icons.pets_outlined,
                                    color: available
                                        ? const Color(0xFFB45309)
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Dr. $name',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        hospital.isNotEmpty
                                            ? '$spec · $hospital'
                                            : spec,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        available
                                            ? 'Available now'
                                            : 'May be unavailable',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: available
                                              ? const Color(0xFF059669)
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.videocam_outlined,
                                  color: Color(0xFFB45309),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _callVet(BuildContext context, Map<String, dynamic> vet) async {
  final userId = parseContactId(vet['user_id']);
  final doctorId = parseContactId(vet['id']);
  if (userId == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This veterinarian cannot be contacted yet.')),
      );
    }
    return;
  }
  if (!context.mounted) return;
  final name = (vet['full_name'] ?? vet['name'] ?? 'Veterinarian').toString();
  await CallLauncher.start(
    context: context,
    peerName: 'Dr. $name',
    receiverUserId: userId.toString(),
    isVideo: true,
    doctorId: doctorId,
  );
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
