import 'package:flutter/material.dart';
import '../../user/screens/call_history_screen.dart';

class ConsultationHistoryScreen extends StatelessWidget {
  const ConsultationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CallHistoryScreen(showDoctorDrawer: true);
  }
}
