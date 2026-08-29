import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../../../routes/app_routes.dart';
import '../../../core/utils/logout_helper.dart';
import '../../../providers/auth_provider.dart';
import '../../profile/widgets/profile_avatar.dart';

class UserSidebar extends StatelessWidget {
  const UserSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.user;
        final l10n = context.l10n;
        final name = user?.name ?? l10n.guest;
        final village = user?.village ?? l10n.unknown;

        return Drawer(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                width: double.infinity,
                decoration: const BoxDecoration(color: Color(0xFFE8F1FF)),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, AppRoutes.profile);
                      },
                      child: ProfileAvatar(
                        user: user,
                        radius: 40,
                        backgroundColor: Colors.white,
                        iconColor: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.villageLabel(village), style: const TextStyle(color: AppColors.primary, fontSize: 14)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  children: [
                    _buildNavItem(context, l10n.dashboard, Icons.grid_view_outlined, AppRoutes.userDashboard),
                    _buildNavItem(context, l10n.aiSymptomChecker, Icons.health_and_safety_outlined, AppRoutes.symptomChecker),
                    _buildNavItem(context, l10n.medicineTracker, Icons.medication_outlined, AppRoutes.medicineTracker),
                    _buildNavItem(context, l10n.medicineAvailability, Icons.local_pharmacy_outlined, AppRoutes.medicineAvailability),
                    _buildNavItem(context, l10n.nearbyClinics, Icons.location_on_outlined, AppRoutes.nearbyClinics),
                    _buildNavItem(context, l10n.consultDoctor, Icons.video_call_outlined, AppRoutes.consultDoctor),
                    _buildNavItem(context, l10n.ashaWorkers, Icons.health_and_safety_outlined, AppRoutes.ashaWorkers),
                    _buildNavItem(context, l10n.messages, Icons.chat_outlined, AppRoutes.chatInbox),
                    _buildNavItem(context, l10n.callHistory, Icons.history, AppRoutes.callHistory),
                    _buildNavItem(context, l10n.myPrescriptions, Icons.description_outlined, AppRoutes.myPrescriptions),
                    _buildNavItem(context, l10n.healthTips, Icons.favorite_border_outlined, AppRoutes.healthTips),
                    _buildNavItem(context, l10n.emergencyHelp, Icons.emergency_outlined, AppRoutes.emergencyHelp, isEmergency: true),
                    const Divider(height: 32),
                    _buildNavItem(context, l10n.profile, Icons.person_outline, AppRoutes.profile),
                    _buildNavItem(context, l10n.settings, Icons.settings_outlined, AppRoutes.settings),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: Text(l10n.logout, style: const TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  Navigator.pop(context);
                  await LogoutHelper.logout(context);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(BuildContext context, String title, IconData icon, String route, {bool isEmergency = false}) {
    // We check the current route to highlight selection
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isSelected = currentRoute == route;

    return ListTile(
      leading: Icon(icon, color: isEmergency ? Colors.red : (isSelected ? AppColors.primary : Colors.grey)),
      title: Text(
        title,
        style: TextStyle(
          color: isEmergency ? Colors.red : (isSelected ? AppColors.primary : Colors.black87),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}
