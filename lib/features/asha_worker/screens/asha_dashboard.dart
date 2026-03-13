import 'package:flutter/material.dart';
import '../../patient/screens/village_patients_screen.dart';
import 'update_health_screen.dart';
import '../../alerts/screens/risk_alert_screen.dart';
import '../../doctor/screens/consult_doctor_screen.dart';
import '../../referral/screens/emergency_referral_screen.dart';
import '../widgets/stats_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/activity_tile.dart';
import '../widgets/emergency_button.dart';
import '../widgets/asha_drawer.dart';

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
      drawer: const AshaDrawer(),
      floatingActionButton: EmergencyButton(
        onTap: () => _navigateTo(context, const EmergencyReferralScreen()),
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
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: QuickActionButton(
                          icon: Icons.person_add_outlined,
                          label: "Register Patient",
                          onTap: () => _navigateTo(
                            context,
                            const VillagePatientsScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: QuickActionButton(
                          icon: Icons.edit_document,
                          label: "Update Health",
                          onTap: () => _navigateTo(
                            context,
                            const UpdateHealthScreen(),
                          ),
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
                          onTap: () => _navigateTo(
                            context,
                            const ConsultDoctorScreen(),
                          ),
                        ),
                      ),
                    ],
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
}
