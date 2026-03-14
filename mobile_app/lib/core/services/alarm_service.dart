import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'notification_service.dart';

class AlarmService {
  static Future<void> init() async {
    await AndroidAlarmManager.initialize();
  }

  static Future<void> scheduleMedicineAlarm(int id, DateTime time, String name, String instructions, String dosage) async {
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
  static void callback(int id, Map<String, dynamic> params) {
    debugPrint('Alarm triggered for $id');
    NotificationService().showMedicineReminder(
      id, 
      params['name'] ?? 'Medicine', 
      params['instructions'] ?? '',
      params['dosage'] ?? '',
    );
  }

  static Future<void> cancelAlarm(int id) async {
    await AndroidAlarmManager.cancel(id);
  }
}
