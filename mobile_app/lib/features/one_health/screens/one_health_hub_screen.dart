import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../screening_disclaimer.dart';

/// Entry hub: Human screening | Livestock screening (shared One Health story).
class OneHealthHubScreen extends StatelessWidget {
  const OneHealthHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('One Health', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            ScreeningDisclaimer.enHuman,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 20),
          _HubCard(
            title: 'Human screening',
            subtitle: 'Symptoms & skin photo triage for people',
            icon: Icons.person_outline,
            color: AppColors.primary,
            onTap: () => Navigator.pushNamed(context, AppRoutes.symptomChecker),
          ),
          const SizedBox(height: 14),
          _HubCard(
            title: 'Livestock screening',
            subtitle: 'Cattle, goat, poultry signs → vet escalation',
            icon: Icons.pets_outlined,
            color: const Color(0xFFB45309),
            onTap: () => Navigator.pushNamed(context, AppRoutes.livestockScreening),
          ),
          const SizedBox(height: 14),
          _HubCard(
            title: 'Child development check',
            subtitle: 'Simple milestone / growth screening',
            icon: Icons.child_care_outlined,
            color: const Color(0xFF0F766E),
            onTap: () => Navigator.pushNamed(context, AppRoutes.childDevelopment),
          ),
          const SizedBox(height: 14),
          _HubCard(
            title: 'Verify Health Information',
            subtitle: 'TrustShield — check WhatsApp health claims',
            icon: Icons.verified_user_outlined,
            color: const Color(0xFF2563EB),
            onTap: () => Navigator.pushNamed(context, AppRoutes.verifyHealthInfo),
          ),
        ],
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HubCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
