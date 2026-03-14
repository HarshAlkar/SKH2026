import 'package:flutter/material.dart';
import '../../../core/widgets/common_appbar.dart';
import '../../../routes/app_routes.dart';
import '../../asha_worker/widgets/asha_drawer.dart';

class ScheduleVisitScreen extends StatelessWidget {
  const ScheduleVisitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        title: "Schedule New Visit",
      ),
      drawer: const AshaDrawer(currentRoute: AppRoutes.scheduleVisit),
      body: const Center(child: Text("Scheduling feature coming soon...")),
    );
  }
}
