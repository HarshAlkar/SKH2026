import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'notification_service.dart';

class AlarmService {
  static Future<void> init() async {
    if (kIsWeb || !Platform.isAndroid) return;
    await AndroidAlarmManager.initialize();
  }

  static Future<void> scheduleMedicineAlarm(int id, DateTime time, String name, String instructions, String dosage) async {
    if (kIsWeb || !Platform.isAndroid) return;
    // Schedule alarm
    await AndroidAlarmManager.oneShotAt(
      time,
      id,
      callback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      params: {
        'name': name,
        'instructions': instructions,
        'dosage': dosage,
        'id': id,
      },
    );
  }

  @pragma('vm:entry-point')
  static Future<void> callback(int id, Map<String, dynamic> params) async {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('Alarm triggered for $id');
    
    final notificationService = NotificationService();
    await notificationService.init();

    await notificationService.showMedicineReminder(
      id, 
      params['name'] ?? 'Medicine', 
      params['instructions'] ?? '',
      params['dosage'] ?? '',
    );
  }

  static Future<void> cancelAlarm(int id) async {
    if (kIsWeb || !Platform.isAndroid) return;
    await AndroidAlarmManager.cancel(id);
  }
}