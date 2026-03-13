import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/user_sidebar.dart';



class DoctorConsultScreen extends StatelessWidget {
  const DoctorConsultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const UserSidebar(),
      appBar: AppBar(
        title: const Text('Consult Doctor'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.primary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),

      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_call, size: 80, color: AppColors.primary),
            SizedBox(height: 20),
            Text(
              'Doctor Consultation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Booking a video call with a specialist...'),
          ],
        ),
      ),
    );
  }
}
