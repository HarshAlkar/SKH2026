import 'dart:io';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'notification_service.dart';

class AlarmService {
  static Future<void> init() async {
<<<<<<< HEAD
    if (Platform.isAndroid) {
      await AndroidAlarmManager.initialize();
      debugPrint('AlarmService Initialized (Android)');
    } else {
      debugPrint('AlarmService bypassed for platform: ${Platform.operatingSystem}');
    }
  }

  static Future<void> scheduleMedicineAlarm(int id, DateTime time, String name, String instructions, String dosage) async {
    if (!Platform.isAndroid) {
      debugPrint('Alarm scheduling skipped on ${Platform.operatingSystem}. Using local notifications fallback if available.');
      return;
    }

    // Ensure the ID is valid for Android alarms (int32)
    final alarmId = id % 2147483647;
    
    debugPrint('Scheduling alarm for $name (ID: $alarmId) at $time');
    
=======
    if (kIsWeb || !Platform.isAndroid) return;
    await AndroidAlarmManager.initialize();
  }

  static Future<void> scheduleMedicineAlarm(int id, DateTime time, String name, String instructions, String dosage) async {
    if (kIsWeb || !Platform.isAndroid) return;
    // Schedule alarm
>>>>>>> fee035fdefda48dc95a9fb53f469dc6dcaed41aa
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
<<<<<<< HEAD
    if (!Platform.isAndroid) return;
    
    final alarmId = id % 2147483647;
    await AndroidAlarmManager.cancel(alarmId);
    debugPrint('Cancelled alarm $alarmId');
=======
    if (kIsWeb || !Platform.isAndroid) return;
    await AndroidAlarmManager.cancel(id);
>>>>>>> fee035fdefda48dc95a9fb53f469dc6dcaed41aa
  }
}