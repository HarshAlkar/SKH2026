import 'package:flutter/material.dart';
import '../../patient/screens/village_patients_screen.dart';
import '../../patient/screens/register_patient_screen.dart';
import 'update_health_screen.dart';
import '../../alerts/screens/risk_alert_screen.dart';
import '../../doctor/screens/consult_doctor_screen.dart';
import '../../reports/screens/village_health_report_screen.dart';
import '../../health_records/screens/health_records_screen.dart';
import '../../visits/screens/village_visits_screen.dart';
import '../widgets/stats_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/activity_tile.dart';

class AshaDashboard extends StatelessWidget {
  const AshaDashboard({super.key});

  final Color primaryColor = const Color(0xFF2A7DE1);
  final Color secondaryBlue = const Color(0xFF4A90E2);
  final Color lightBackground = const Color(0xFFF5F7FA);

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
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
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: lightBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: CircleAvatar(
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Icon(Icons.person_outline, color: primaryColor),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateTo(context, const RegisterPatientScreen()),
        backgroundColor: const Color(0xFF2F4DB6),
        tooltip: 'Register New Patient',
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Good Morning Sunita 👋",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Village Health Overview",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: primaryColor, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stats Cards Grid
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.1,
                children: [
                  StatsCard(
                    icon: Icons.people_alt_outlined,
                    number: "142",
                    label: "TOTAL PATIENTS",
                    iconColor: primaryColor,
                    iconBackgroundColor: primaryColor.withOpacity(0.1),
                  ),
                  StatsCard(
                    icon: Icons.monitor_heart_outlined,
                    number: "08",
                    label: "HIGH RISK",
                    iconColor: Colors.redAccent,
                    iconBackgroundColor: Colors.redAccent.withOpacity(0.1),
                  ),
                  StatsCard(
                    icon: Icons.calendar_month_outlined,
                    number: "12",
                    label: "PENDING VISITS",
                    iconColor: Colors.orange,
                    iconBackgroundColor: Colors.orange.withOpacity(0.1),
                  ),
                  StatsCard(
                    icon: Icons.notifications_none_outlined,
                    number: "03",
                    label: "NEW ALERTS",
                    iconColor: secondaryBlue,
                    iconBackgroundColor: secondaryBlue.withOpacity(0.1),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Quick Actions
              const Text(
                "QUICK ACTIONS",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.person_add_outlined,
                      label: "Register Patient",
                      onTap: () =>
                          _navigateTo(context, const VillagePatientsScreen()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.edit_document,
                      label: "Update Health",
                      onTap: () =>
                          _navigateTo(context, const UpdateHealthScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.warning_amber_rounded,
                      label: "View Risk Alerts",
                      onTap: () =>
                          _navigateTo(context, const RiskAlertScreen()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.medical_services_outlined,
                      label: "Consult Doctor",
                      onTap: () =>
                          _navigateTo(context, const ConsultDoctorScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Recent Activity Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "RECENT ACTIVITY",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Colors.grey,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      "View All",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ActivityTile(
                icon: Icons.content_paste,
                name: "Ramesh Patil",
                activity: "Fever reported • 10 mins ago",
                iconBackgroundColor: const Color(0xFFE8F1FF), // Light Blue
                iconColor: primaryColor,
              ),
              ActivityTile(
                icon: Icons.check_circle_outline,
                name: "Sita Devi",
                activity: "Vaccination completed • 2 hrs ago",
                iconBackgroundColor: const Color(0xFFE8F5E9), // Light Green
                iconColor: Colors.green,
              ),
              ActivityTile(
                icon: Icons.error_outline,
                name: "Amit Shinde",
                activity: "High BP Alert • 4 hrs ago",
                iconBackgroundColor: const Color(0xFFFFEBEE), // Light Red
                iconColor: Colors.redAccent,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: primaryColor),
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
            onTap: () => Navigator.pop(context),
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
            onTap: () => Navigator.pop(context),
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
