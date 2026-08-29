import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../routes/app_routes.dart';
import '../../../core/utils/logout_helper.dart';
import '../../../providers/auth_provider.dart';
import '../../profile/widgets/profile_avatar.dart';
import '../../../core/emergency_comms/widgets/offline_emergency_status.dart';
import '../../../l10n/l10n.dart';

class AshaSidebar extends StatelessWidget {
  const AshaSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.user;
        final l10n = context.l10n;
        final name = user?.name ?? l10n.ashaWorker;
        final village = user?.village ?? l10n.assignedVillage;

        return Drawer(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                width: double.infinity,
                decoration: const BoxDecoration(color: Color(0xFFF0FFF4)), // Light green for Asha
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
                        iconColor: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.villageLabel(village), style: const TextStyle(color: Colors.green, fontSize: 14)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  children: [
                    _buildNavItem(context, l10n.dashboard, Icons.dashboard_outlined, AppRoutes.ashaDashboard),
                    _buildNavItem(context, l10n.villagePatients, Icons.people_outline, AppRoutes.villagePatients),
                    _buildNavItem(context, l10n.callChat, Icons.call_outlined, AppRoutes.ashaCall),
                    _buildNavItem(context, l10n.messages, Icons.chat_outlined, AppRoutes.chatInbox),
                    _buildNavItem(context, l10n.callHistory, Icons.history, AppRoutes.callHistory),
                    _buildNavItem(context, l10n.riskAlerts, Icons.notification_important_outlined, AppRoutes.riskAlerts),
                    _buildNavItem(context, l10n.healthReports, Icons.bar_chart, AppRoutes.villageHealthReport),
                    _buildNavItem(context, l10n.registerPatient, Icons.person_add_alt_1_outlined, AppRoutes.registerPatient),
                    _buildNavItem(context, l10n.villageVisits, Icons.home_outlined, AppRoutes.villageVisits),
                    _buildNavItem(context, l10n.updateStock, Icons.inventory_2_outlined, AppRoutes.updateStock),
                    _buildNavItem(context, l10n.consultDoctor, Icons.chat_bubble_outline, AppRoutes.registeredDoctors),
                    _buildNavItem(context, l10n.healthRecords, Icons.folder_open_outlined, AppRoutes.healthRecords),
                    _buildNavItem(context, l10n.emergencyReferral, Icons.emergency_share, AppRoutes.emergencyReferral),
                    _buildNavItem(context, l10n.referralHistory, Icons.history, AppRoutes.referralHistory),
                    const Divider(height: 32),
                    _buildNavItem(context, l10n.profile, Icons.person_outline, AppRoutes.profile),
                    _buildNavItem(context, l10n.settings, Icons.settings_outlined, AppRoutes.ashaSettings),
                  ],
                ),
              ),
              const OfflineEmergencyStatusTile(),
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

  Widget _buildNavItem(BuildContext context, String title, IconData icon, String route) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isSelected = currentRoute == route;

    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.green : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.green : Colors.black87,
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
