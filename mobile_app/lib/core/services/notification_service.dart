import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io' show Platform;
import '../../routes/app_routes.dart';
import '../keys/navigator_key.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final FlutterTts flutterTts = FlutterTts();

  Future<void> init() async {
    InitializationSettings initializationSettings;
    
<<<<<<< HEAD
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
=======
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
>>>>>>> fee035fdefda48dc95a9fb53f469dc6dcaed41aa

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

    // Request permissions for Android 13+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    
    debugPrint('NotificationService Initialized');
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

    const DarwinNotificationDetails darwinPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    final payload = jsonEncode({
      'id': id, 
      'name': name, 
      'instructions': instructions,
      'dosage': dosage,
    });

<<<<<<< HEAD
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
    );

=======
>>>>>>> fee035fdefda48dc95a9fb53f469dc6dcaed41aa
    await flutterLocalNotificationsPlugin.show(
      id,
      'Medicine Reminder: $name',
      'It is time to take your medicine ($dosage). $instructions',
      platformChannelSpecifics,
      payload: payload,
    );
    
    // Voice reminder (Hindi and English)
    await _speak('Attention: It is time to take your medicine $name, dosage $dosage. Dawai khane ka time ho gaya hai.');
  }

  Future<void> _speak(String text) async {
    try {
      await flutterTts.setLanguage("hi-IN");
      await flutterTts.setPitch(1.0);
      await flutterTts.setSpeechRate(0.5); // Slightly slower for clarity
      await flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS Error: $e');
    }
  }
}
