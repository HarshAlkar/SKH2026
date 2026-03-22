import 'package:flutter/material.dart';
import 'package:hs053/features/activity/models/activity_model.dart';
import '../widgets/activity_card.dart';
import 'package:hs053/core/widgets/common_appbar.dart';
import 'package:hs053/features/asha_worker/widgets/asha_drawer.dart';
import 'package:hs053/core/routes/app_routes.dart';

class AllActivityScreen extends StatelessWidget {
  const AllActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFF5F7FA);

    final List<ActivityModel> activities = [
      ActivityModel(
        id: '1',
        patientName: 'Ramesh Patil',
        activityType: 'Health Update',
        description: 'Fever reported (101°F). Advised paracetamol and rest.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        village: 'Rampur',
        reportedBy: 'Sunita (ASHA)',
      ),
      ActivityModel(
        id: '2',
        patientName: 'Sita Devi',
        activityType: 'Vaccination',
        description: 'Polio drops administered to child (3 yrs).',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        village: 'Rampur',
        reportedBy: 'Sunita (ASHA)',
      ),
      ActivityModel(
        id: '3',
        patientName: 'Amit Shinde',
        activityType: 'Risk Alert',
        description: 'High BP detected (160/100). Emergency referral created.',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        village: 'Kaman',
        reportedBy: 'AI System',
      ),
      ActivityModel(
        id: '4',
        patientName: 'Gopal Krishan',
        activityType: 'Visit Completed',
        description: 'Monthly routine checkup done. All vitals normal.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        village: 'Vikhroli',
        reportedBy: 'Sunita (ASHA)',
      ),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const CommonAppBar(title: "All Activities"),
      drawer: const AshaDrawer(currentRoute: AppRoutes.ashaAllActivity),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            return ActivityCard(
              activity: activity,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.ashaActivityDetails,
                  arguments: activity,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
