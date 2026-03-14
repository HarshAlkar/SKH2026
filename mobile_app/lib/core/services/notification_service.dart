import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io' show Platform;
import '../../routes/app_routes.dart';
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
          final data = jsonDecode(details.payload!);
          navigatorKey.currentState?.pushNamed(
            AppRoutes.medicineCall,
            arguments: data,
          );
        }
      },
    );
  }

  Future<void> showMedicineReminder(int id, String name, String instructions, String dosage) async {
    NotificationDetails platformChannelSpecifics;

    if (!kIsWeb && Platform.isAndroid) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
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
      platformChannelSpecifics = const NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );
    } else {
      platformChannelSpecifics = const NotificationDetails();
    }

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
    
    // Voice reminder (Hindi and English)
    await _speak('Reminder: It is time to take your medicine $name, dosage $dosage. Dawai khane ka time ho gaya hai.');
  }

  Future<void> _speak(String text) async {
    // Try to set to Hindi first
    await flutterTts.setLanguage("hi-IN");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }
}
