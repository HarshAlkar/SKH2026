import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../widgets/notification_card.dart';
import '../../../core/widgets/common_appbar.dart';
import '../../asha_worker/widgets/asha_drawer.dart';
import '../../../routes/app_routes.dart';

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
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      severityLevel: SeverityLevel.critical,
    ),
    NotificationModel(
      id: '2',
      patientName: 'Ramesh Patil',
      alertType: 'AI Symptom Alert',
      symptoms: 'High fever and severe headache.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
      severityLevel: SeverityLevel.high,
    ),
    NotificationModel(
      id: '3',
      patientName: 'Shanti Devi',
      alertType: 'AI Symptom Alert',
      symptoms: 'Persistent cough and fatigue.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      severityLevel: SeverityLevel.medium,
    ),
  ];

  void _markAllAsRead() {
    setState(() {
      for (var i = 0; i < _notifications.length; i++) {
        _notifications[i] = NotificationModel(
          id: _notifications[i].id,
          patientName: _notifications[i].patientName,
          alertType: _notifications[i].alertType,
          symptoms: _notifications[i].symptoms,
          timestamp: _notifications[i].timestamp,
          severityLevel: _notifications[i].severityLevel,
          isRead: true,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    Navigator.pushNamed(context, AppRoutes.ashaPatientDetails, arguments: notification.patientName);
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2F4DB6);
    const Color backgroundColor = Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: CommonAppBar(
        title: "Notifications",
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.white, size: 20),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AshaDrawer(currentRoute: AppRoutes.ashaNotifications),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: _notifications.length,
          itemBuilder: (context, index) {
            final notification = _notifications[index];
            return Dismissible(
              key: Key(notification.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.mark_email_read, color: primaryColor),
              ),
              onDismissed: (_) {
                setState(() {
                  _notifications.removeAt(index);
                });
              },
              child: NotificationCard(
                notification: notification,
                onTap: () => _handleNotificationTap(notification),
              ),
            );
          },
        ),
      ),
    );
  }
}
