import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../../routes/app_routes.dart';
import '../../main.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FlutterTts flutterTts = FlutterTts();

  static const AndroidNotificationDetails _androidDetails = AndroidNotificationDetails(
    'medicine_reminders',
    'Medicine Reminders',
    channelDescription: 'Notifications for medicine reminders',
    importance: Importance.max,
    priority: Priority.high,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,
    playSound: true,
  );

  static const DarwinNotificationDetails _darwinDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    interruptionLevel: InterruptionLevel.timeSensitive,
  );

  static const NotificationDetails _platformDetails = NotificationDetails(
    android: _androidDetails,
    iOS: _darwinDetails,
    macOS: _darwinDetails,
  );

  Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          final data = jsonDecode(details.payload!);
          navigatorKey.currentState?.pushNamed(
            AppRoutes.medicineCall,
            arguments: data,
          );
        }
      },
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    debugPrint('NotificationService Initialized');
  }

  Future<void> showMedicineReminder(
    int id,
    String name,
    String instructions,
    String dosage,
  ) async {
    final payload = jsonEncode({
      'id': id,
      'name': name,
      'instructions': instructions,
      'dosage': dosage,
    });

    await flutterLocalNotificationsPlugin.show(
      id,
      'Medicine Reminder: $name',
      'It is time to take your medicine ($dosage). $instructions',
      _platformDetails,
      payload: payload,
    );

    await _speak(
      'Attention: It is time to take your medicine $name, dosage $dosage. Dawai khane ka time ho gaya hai.',
    );
  }

  Future<void> scheduleMedicineReminder({
    required int id,
    required DateTime time,
    required String name,
    required String instructions,
    required String dosage,
  }) async {
    final payload = jsonEncode({
      'id': id,
      'name': name,
      'instructions': instructions,
      'dosage': dosage,
    });

    var scheduled = tz.TZDateTime.from(time, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Medicine Reminder: $name',
      'It is time to take your medicine ($dosage). $instructions',
      scheduled,
      _platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  Future<void> cancelReminder(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> _speak(String text) async {
    try {
      await flutterTts.setLanguage('hi-IN');
      await flutterTts.setPitch(1.0);
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS Error: $e');
    }
  }
}
