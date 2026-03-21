import 'dart:io';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'notification_service.dart';

class AlarmService {
  static Future<void> init() async {
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
    
    await AndroidAlarmManager.oneShotAt(
      time,
      alarmId,
      callback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      params: {
        'name': name,
        'instructions': instructions,
        'dosage': dosage,
        'id': id,
        'time': time.toIso8601String(),
      },
    );
  }

  @pragma('vm:entry-point')
  static void callback(int id, Map<String, dynamic> params) {
    debugPrint('--- ALARM TRIGGERED ---');
    debugPrint('Alarm ID: $id');
    debugPrint('Medicine: ${params['name']}');
    
    // Trigger notification
    NotificationService().showMedicineReminder(
      params['id'] ?? id, 
      params['name'] ?? 'Medicine', 
      params['instructions'] ?? '',
      params['dosage'] ?? '',
    );

    // Reschedule for tomorrow
    try {
      final lastTime = DateTime.parse(params['time']);
      final nextTime = lastTime.add(const Duration(days: 1));
      
      scheduleMedicineAlarm(
        params['id'] ?? id,
        nextTime,
        params['name'] ?? 'Medicine',
        params['instructions'] ?? '',
        params['dosage'] ?? '',
      );
      debugPrint('Rescheduled for: $nextTime');
    } catch (e) {
      debugPrint('Error rescheduling alarm: $e');
    }
  }

  static Future<void> cancelAlarm(int id) async {
    if (!Platform.isAndroid) return;
    
    final alarmId = id % 2147483647;
    await AndroidAlarmManager.cancel(alarmId);
    debugPrint('Cancelled alarm $alarmId');
  }
}
