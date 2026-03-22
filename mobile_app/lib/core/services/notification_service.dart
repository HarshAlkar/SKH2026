import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io' show Platform;
import 'package:timezone/timezone.dart' as tz;
import 'package:hs053/core/routes/app_routes.dart';
import '../../main.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final FlutterTts flutterTts = FlutterTts();

  Future<void> init() async {
    InitializationSettings initializationSettings;
    
    if (kIsWeb) {
       initializationSettings = const InitializationSettings(
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
      );
    } else if (Platform.isAndroid) {
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      initializationSettings = const InitializationSettings(
        android: initializationSettingsAndroid,
      );
    } else {
       initializationSettings = const InitializationSettings(
        iOS: DarwinInitializationSettings(),
      );
    }

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          try {
            final data = jsonDecode(details.payload!);
            navigatorKey.currentState?.pushNamed(
              AppRoutes.medicineCall,
              arguments: data,
            );
          } catch (e) {
            debugPrint('Error handling notification response: $e');
          }
        }
      },
    );

    // Request permissions for Android 13+
    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
    }
    
    debugPrint('NotificationService Initialized');
  }

  Future<void> showMedicineReminder(int id, String name, String instructions, String dosage) async {
    final platformChannelSpecifics = _getNotificationDetails();

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
      platformChannelSpecifics,
      payload: payload,
    );
    
    // Voice reminder
    await _speak('Attention: It is time to take your medicine $name, dosage $dosage. Dawai khane ka time ho gaya hai.');
  }

  Future<void> scheduleMedicineReminder({
    required int id,
    required String name,
    required String instructions,
    required String dosage,
    required DateTime scheduledTime,
  }) async {
    final platformChannelSpecifics = _getNotificationDetails();

    final payload = jsonEncode({
      'id': id, 
      'name': name, 
      'instructions': instructions,
      'dosage': dosage,
    });

    // Ensure we are scheduling in the future
    if (scheduledTime.isBefore(DateTime.now())) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Medicine Reminder: $name',
      'Time for $dosage of $name. $instructions',
      tz.TZDateTime.from(scheduledTime, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
    
    debugPrint('Scheduled notification for $name at $scheduledTime');
  }

  Future<void> testScheduledNotification() async {
    debugPrint('Setting test notification for 10 seconds from now...');
    final time = DateTime.now().add(const Duration(seconds: 10));
    await scheduleMedicineReminder(
      id: 999,
      name: 'Test Medicine',
      instructions: 'Take with water',
      dosage: '1 Tablet',
      scheduledTime: time,
    );
  }

  NotificationDetails _getNotificationDetails() {
    if (!kIsWeb && Platform.isAndroid) {
      return const NotificationDetails(
        android: AndroidNotificationDetails(
          'medicine_reminders',
          'Medicine Reminders',
          channelDescription: 'Notifications for medicine reminders',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          playSound: true,
          styleInformation: BigTextStyleInformation(''),
        ),
      );
    }
    return const NotificationDetails(iOS: DarwinNotificationDetails());
  }

  Future<void> _speak(String text) async {
    try {
      await flutterTts.setLanguage("hi-IN");
      await flutterTts.setPitch(1.0);
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS Error: $e');
    }
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
