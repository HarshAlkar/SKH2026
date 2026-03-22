import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hs053/core/routes/app_routes.dart';
import 'package:hs053/shared/providers/auth_provider.dart';

class AshaSidebar extends StatelessWidget {
  const AshaSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.user;
        final name = user?.name ?? 'Asha Worker';
        final village = user?.village ?? 'Assigned Village';

        return Drawer(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                width: double.infinity,
                decoration: const BoxDecoration(color: Color(0xFFF0FFF4)), // Light green for Asha
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person_outline, size: 50, color: Colors.green),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Text('Village: $village', style: const TextStyle(color: Colors.green, fontSize: 14)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  children: [
                    _buildNavItem(context, 'Dashboard', Icons.dashboard_outlined, AppRoutes.ashaDashboard),
                    _buildNavItem(context, 'Village Patients', Icons.people_outline, AppRoutes.villagePatients),
                    _buildNavItem(context, 'Risk Alerts', Icons.notification_important_outlined, AppRoutes.riskAlerts),
                    _buildNavItem(context, 'Health Reports', Icons.bar_chart, AppRoutes.villageHealthReport),
                    _buildNavItem(context, 'Register Patient', Icons.person_add_alt_1_outlined, AppRoutes.registerPatient),
                    _buildNavItem(context, 'Village Visits', Icons.home_outlined, AppRoutes.villageVisits),
                    _buildNavItem(context, 'Consult Doctor', Icons.chat_bubble_outline, AppRoutes.registeredDoctors),
                    _buildNavItem(context, 'Health Records', Icons.folder_open_outlined, AppRoutes.healthRecords),
                    const Divider(height: 32),
                    _buildNavItem(context, 'Settings', Icons.settings_outlined, AppRoutes.ashaSettings),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.roleSelection, (route) => false);
                  }
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
