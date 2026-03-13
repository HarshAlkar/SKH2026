import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';

class UserSidebar extends StatelessWidget {
  const UserSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            width: double.infinity,
            decoration: const BoxDecoration(color: Color(0xFFE8F1FF)),
            child: const Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 50, color: Colors.grey),
                ),
                SizedBox(height: 16),
                Text(
                  'Ramesh Patil',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                SizedBox(height: 4),
                Text('Village: Kaman', style: TextStyle(color: AppColors.primary, fontSize: 14)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              children: [
                _buildNavItem(context, 'Dashboard', Icons.grid_view_outlined, AppRoutes.userDashboard),
                _buildNavItem(context, 'AI Symptom Checker', Icons.health_and_safety_outlined, AppRoutes.symptomChecker),
                _buildNavItem(context, 'Medicine Tracker', Icons.medication_outlined, AppRoutes.medicineTracker),
                _buildNavItem(context, 'Nearby Clinics', Icons.location_on_outlined, AppRoutes.nearbyClinics),
                _buildNavItem(context, 'Consult Doctor', Icons.video_call_outlined, AppRoutes.consultDoctor),
                _buildNavItem(context, 'My Prescriptions', Icons.description_outlined, AppRoutes.myPrescriptions),
                _buildNavItem(context, 'Health Tips', Icons.favorite_border_outlined, AppRoutes.healthTips),
                _buildNavItem(context, 'Emergency Help', Icons.emergency_outlined, AppRoutes.emergencyHelp, isEmergency: true),
                const Divider(height: 32),
                _buildNavItem(context, 'Settings', Icons.settings_outlined, AppRoutes.settings),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.grey),
            title: const Text('Logout', style: TextStyle(color: Colors.grey)),
            onTap: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.roleSelection, (route) => false),
          ),
          const SizedBox(height: 20),
        ],
      ),
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
