import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hs053/shared/providers/auth_provider.dart';
import 'package:hs053/core/routes/app_routes.dart';

class AshaDrawer extends StatelessWidget {
  final String currentRoute;

  const AshaDrawer({super.key, required this.currentRoute});

  void _navigateTo(BuildContext context, String routeName) {
    if (currentRoute == routeName) {
      Navigator.pop(context); // Just close drawer if already on the page
      return;
    }
    
    Navigator.pop(context); // Close drawer first
    Navigator.pushReplacementNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    const Color primaryColor = Color(0xFF2A7DE1);

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: primaryColor),
            accountName: Text(
              user?.name ?? "ASHA Worker",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text("Phone: ${user?.phoneNumber ?? 'N/A'}"),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.blue),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context: context,
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  route: AppRoutes.ashaDashboard,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.analytics_outlined,
                  title: 'Village Health Report',
                  route: AppRoutes.villageHealthReport,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.person_add_alt_1_outlined,
                  title: 'Register Patient',
                  route: AppRoutes.registerPatient,
                ),
                 _buildDrawerItem(
                  context: context,
                  icon: Icons.people_outline,
                  title: 'Village Patients',
                  route: AppRoutes.villagePatients,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.directions_walk,
                  title: 'Village Visits',
                  route: AppRoutes.villageVisits,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.folder_shared_outlined,
                  title: 'Health Records',
                  route: AppRoutes.healthRecords,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.warning_amber_rounded,
                  title: 'Risk Alerts',
                  route: AppRoutes.riskAlerts,
                  iconColor: Colors.orange,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.medical_services_outlined,
                  title: 'Consult Doctor',
                  route: AppRoutes.ashaConsultDoctor,
                  iconColor: Colors.green,
                ),
                const Divider(),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  route: AppRoutes.ashaSettings,
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () async {
                    await authProvider.logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.roleSelection,
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
    Color? iconColor,
  }) {
    final bool isSelected = currentRoute == route;
    const Color primaryColor = Color(0xFF2A7DE1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? primaryColor : (iconColor ?? Colors.grey[700]),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? primaryColor : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () => _navigateTo(context, route),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
