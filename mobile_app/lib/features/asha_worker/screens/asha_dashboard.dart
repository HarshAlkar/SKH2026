import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';
import '../../../core/widgets/common_appbar.dart';
import '../widgets/stats_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/emergency_button.dart';
import '../widgets/asha_drawer.dart';
import '../widgets/activity_tile.dart';
import '../../notifications/widgets/notification_badge.dart';
import '../../activity/models/activity_model.dart';

class AshaDashboard extends StatelessWidget {
  const AshaDashboard({super.key});

  final Color primaryColor = const Color(0xFF2A7DE1);
  final Color secondaryBlue = const Color(0xFF4A90E2);
  final Color lightBackground = const Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFF5F7FA);
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const CommonAppBar(
        title: "ASHA Dashboard",
        showNotification: false,
      ),
      drawer: const AshaDrawer(currentRoute: AppRoutes.ashaDashboard),
      floatingActionButton: EmergencyButton(
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.emergencyReferral);
        },
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
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.ashaNotifications);
                        },
                      ),
                      const Positioned(
                        right: 8,
                        top: 8,
                        child: NotificationBadge(count: 3),
                      ),
                    ],
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
                childAspectRatio: 1.0,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.villagePatients),
                    child: StatsCard(
                      icon: Icons.people_alt_outlined,
                      number: "142",
                      label: "TOTAL PATIENTS",
                      iconColor: primaryColor,
                      iconBackgroundColor: primaryColor.withOpacity(0.1),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.riskAlerts),
                    child: StatsCard(
                      icon: Icons.monitor_heart_outlined,
                      number: "08",
                      label: "HIGH RISK",
                      iconColor: Colors.redAccent,
                      iconBackgroundColor: Colors.redAccent.withOpacity(0.1),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.villageVisits),
                    child: StatsCard(
                      icon: Icons.calendar_month_outlined,
                      number: "12",
                      label: "PENDING VISITS",
                      iconColor: Colors.orange,
                      iconBackgroundColor: Colors.orange.withOpacity(0.1),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.ashaNotifications),
                    child: StatsCard(
                      icon: Icons.notifications_none_outlined,
                      number: "03",
                      label: "NEW ALERTS",
                      iconColor: secondaryBlue,
                      iconBackgroundColor: secondaryBlue.withOpacity(0.1),
                    ),
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
                          onTap: () => Navigator.pushNamed(context, AppRoutes.villagePatients),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: QuickActionButton(
                          icon: Icons.edit_document,
                          label: "Update Health",
                          onTap: () => Navigator.pushNamed(context, AppRoutes.updateHealth),
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
                          onTap: () => Navigator.pushNamed(context, AppRoutes.riskAlerts),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: QuickActionButton(
                          icon: Icons.medical_services_outlined,
                          label: "Consult Doctor",
                          onTap: () => Navigator.pushNamed(context, AppRoutes.ashaConsultDoctor),
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
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.ashaAllActivity);
                    },
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
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.ashaActivityDetails,
                    arguments: ActivityModel(
                      id: '1',
                      patientName: 'Ramesh Patil',
                      activityType: 'Health Update',
                      description: 'Fever reported (101°F). Advised paracetamol and rest.',
                      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
                      village: 'Rampur',
                      reportedBy: 'Sunita (ASHA)',
                    ),
                  );
                },
              ),
              ActivityTile(
                icon: Icons.check_circle_outline,
                name: "Sita Devi",
                activity: "Vaccination completed • 2 hrs ago",
                iconBackgroundColor: const Color(0xFFE8F5E9), // Light Green
                iconColor: Colors.green,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.ashaActivityDetails,
                    arguments: ActivityModel(
                      id: '2',
                      patientName: 'Sita Devi',
                      activityType: 'Vaccination',
                      description: 'Polio drops administered to child (3 yrs).',
                      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
                      village: 'Rampur',
                      reportedBy: 'Sunita (ASHA)',
                    ),
                  );
                },
              ),
              ActivityTile(
                icon: Icons.error_outline,
                name: "Amit Shinde",
                activity: "High BP Alert • 4 hrs ago",
                iconBackgroundColor: const Color(0xFFFFEBEE), // Light Red
                iconColor: Colors.redAccent,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.ashaActivityDetails,
                    arguments: ActivityModel(
                      id: '3',
                      patientName: 'Amit Shinde',
                      activityType: 'Risk Alert',
                      description: 'High BP detected (160/100). Emergency referral created.',
                      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
                      village: 'Kaman',
                      reportedBy: 'AI System',
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
