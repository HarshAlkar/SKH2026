import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../widgets/notification_card.dart';
import '../../asha_worker/widgets/asha_drawer.dart';
import '../../referral/screens/emergency_referral_screen.dart';
import '../../patient/screens/patient_details_screen.dart';
import '../../patient/models/patient_model.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<NotificationModel> _notifications = [
    NotificationModel(
      id: '1',
      patientName: 'Lakshmi Devi',
      alertType: 'AI Symptom Alert',
      symptoms: 'Chest pain, difficulty breathing.',
      timestamp: '10 mins ago',
      severityLevel: NotificationSeverity.critical,
    ),
    NotificationModel(
      id: '2',
      patientName: 'Ramesh Patil',
      alertType: 'AI Symptom Alert',
      symptoms: 'High fever and severe headache.',
      timestamp: '25 mins ago',
      severityLevel: NotificationSeverity.critical,
    ),
    NotificationModel(
      id: '3',
      patientName: 'Shanti Devi',
      alertType: 'AI Symptom Alert',
      symptoms: 'Persistent cough and fatigue.',
      timestamp: '1 hour ago',
      severityLevel: NotificationSeverity.normal,
    ),
  ];

  void _markAllAsRead() {
    setState(() {
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(
          status: NotificationStatus.read,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("All notifications marked as read")),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    if (notification.severityLevel == NotificationSeverity.critical) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const EmergencyReferralScreen(),
        ),
      );
    } else {
      // Create a dummy patient model for navigation
      final patient = PatientModel(
        name: notification.patientName,
        age: 0,
        village: 'Unknown',
        status: 'Alert Received',
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PatientDetailsScreen(patient: patient),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2A7DE1);
    const Color backgroundColor = Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: const AshaDrawer(),
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text(
              "Read All",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 60,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No new alerts",
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return NotificationCard(
                  notification: notification,
                  onTap: () => _handleNotificationTap(notification),
                  onDismissed: () {
                    setState(() {
                      _notifications.removeAt(index);
                    });
                  },
                );
              },
            ),
    );
  }
}
