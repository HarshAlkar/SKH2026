import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

class AlarmService {
  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> init() async {
    if (!_isAndroid) {
      debugPrint('AlarmService: using local notifications on this platform');
      return;
    }
    await AndroidAlarmManager.initialize();
    debugPrint('AlarmService Initialized');
  }

  static Future<void> scheduleMedicineAlarm(
    int id,
    DateTime time,
    String name,
    String instructions,
    String dosage,
  ) async {
    final alarmId = id % 2147483647;
    debugPrint('Scheduling alarm for $name (ID: $alarmId) at $time');

    if (!_isAndroid) {
      await NotificationService().scheduleMedicineReminder(
        id: alarmId,
        time: time,
        name: name,
        instructions: instructions,
        dosage: dosage,
      );
      return;
    }

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

    NotificationService().showMedicineReminder(
      params['id'] ?? id,
      params['name'] ?? 'Medicine',
      params['instructions'] ?? '',
      params['dosage'] ?? '',
    );

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
    final alarmId = id % 2147483647;
    await NotificationService().cancelReminder(alarmId);
    if (_isAndroid) {
      await AndroidAlarmManager.cancel(alarmId);
    }
    debugPrint('Cancelled alarm $alarmId');
  }
}
