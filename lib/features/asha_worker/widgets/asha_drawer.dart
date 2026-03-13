import 'package:flutter/material.dart';
import '../screens/asha_dashboard.dart';
import '../../patient/screens/village_patients_screen.dart';
import '../../visits/screens/village_visits_screen.dart';
import '../../health_records/screens/health_records_screen.dart';
import '../../alerts/screens/risk_alert_screen.dart';
import '../../doctor/screens/consult_doctor_screen.dart';
import '../../reports/screens/village_health_report_screen.dart';
import '../../referral/screens/emergency_referral_screen.dart';
import '../../settings/screens/settings_screen.dart';

class AshaDrawer extends StatelessWidget {
  const AshaDrawer({super.key});

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2A7DE1);

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: primaryColor),
            accountName: const Text(
              "Sunita Sharma",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: const Text("Worker ID: AW-208154"),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.blue),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(context, const AshaDashboard());
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: const Text('Village Health Report'),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(context, const VillageHealthReportScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_add_alt_1_outlined),
            title: const Text('Register Patient'),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(context, const VillagePatientsScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.directions_walk),
            title: const Text('Village Visits'),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(context, const VillageVisitsScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder_shared_outlined),
            title: const Text('Health Records'),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(context, const HealthRecordsScreen());
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
            ),
            title: const Text('Risk Alerts'),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(context, const RiskAlertScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.emergency_share, color: Colors.red),
            title: const Text('Emergency Referral'),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(context, const EmergencyReferralScreen());
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.medical_services_outlined,
              color: Colors.green,
            ),
            title: const Text('Consult Doctor'),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(context, const ConsultDoctorScreen());
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(context, const SettingsScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
