import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../../routes/app_routes.dart';
import '../../main.dart';
import 'settings_store.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FlutterTts flutterTts = FlutterTts();

  static const AndroidNotificationDetails _medicineAndroid = AndroidNotificationDetails(
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

  static const AndroidNotificationDetails _callAndroid = AndroidNotificationDetails(
    'incoming_calls',
    'Incoming Calls',
    channelDescription: 'Notifications for incoming video and audio calls',
    importance: Importance.max,
    priority: Priority.max,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.call,
    visibility: NotificationVisibility.public,
    playSound: true,
    ongoing: true,
  );

  static const AndroidNotificationDetails _chatAndroid = AndroidNotificationDetails(
    'chat_messages',
    'Messages',
    channelDescription: 'Notifications for new chat messages',
    importance: Importance.high,
    priority: Priority.high,
    category: AndroidNotificationCategory.message,
    visibility: NotificationVisibility.public,
    playSound: true,
  );

  static const DarwinNotificationDetails _darwinDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    interruptionLevel: InterruptionLevel.timeSensitive,
  );

  static const DarwinNotificationDetails _callDarwin = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    interruptionLevel: InterruptionLevel.critical,
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
          handlePayload(details.payload!);
        }
      },
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    final launch = await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      final payload = launch?.notificationResponse?.payload;
      if (payload != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => handlePayload(payload));
      }
    }

    debugPrint('NotificationService Initialized');
  }

  void handlePayload(String payload) {
    try {
      final data = jsonDecode(payload);
      if (data is! Map) return;
      final map = Map<String, dynamic>.from(data);
      final type = map['type']?.toString() ?? 'medicine';
      final nav = navigatorKey.currentState;
      if (nav == null) return;

      if (type == 'call') {
        nav.pushNamed(AppRoutes.incomingCall, arguments: map);
        return;
      }

      if (type == 'chat') {
        nav.pushNamed(AppRoutes.chatThread, arguments: map);
        return;
      }

      nav.pushNamed(AppRoutes.medicineCall, arguments: map);
    } catch (e) {
      debugPrint('Notification payload error: $e');
    }
  }

  Future<void> showMedicineReminder(
    int id,
    String name,
    String instructions,
    String dosage,
  ) async {
    if (!SettingsStore.instance.medicineEnabled) return;
    final payload = jsonEncode({
      'type': 'medicine',
      'id': id,
      'name': name,
      'instructions': instructions,
      'dosage': dosage,
    });

    await flutterLocalNotificationsPlugin.show(
      id,
      'Medicine Reminder: $name',
      'It is time to take your medicine ($dosage). $instructions',
      const NotificationDetails(
        android: _medicineAndroid,
        iOS: _darwinDetails,
        macOS: _darwinDetails,
      ),
      payload: payload,
    );

    await _speak(
      'Attention: It is time to take your medicine $name, dosage $dosage. Dawai khane ka time ho gaya hai.',
    );
  }

  Future<void> showIncomingCall({
    required String consultationId,
    required String callerName,
    required String callType,
    int? callerUserId,
  }) async {
    if (!SettingsStore.instance.callsEnabled) return;
    final payload = jsonEncode({
      'type': 'call',
      'consultationId': consultationId,
      'callerName': callerName,
      'callType': callType,
      'callerUserId': callerUserId,
    });
    final isVideo = callType.toUpperCase() == 'VIDEO';
    await flutterLocalNotificationsPlugin.show(
      _callNotifId(consultationId),
      isVideo ? 'Incoming video call' : 'Incoming audio call',
      '$callerName is calling you',
      const NotificationDetails(
        android: _callAndroid,
        iOS: _callDarwin,
        macOS: _callDarwin,
      ),
      payload: payload,
    );
  }

  Future<void> cancelIncomingCall(String consultationId) async {
    await flutterLocalNotificationsPlugin.cancel(_callNotifId(consultationId));
  }

  Future<void> showChatMessage({
    required int threadId,
    required int peerUserId,
    required String peerName,
    required String text,
    String? peerPhone,
  }) async {
    if (!SettingsStore.instance.chatEnabled) return;
    final payload = jsonEncode({
      'type': 'chat',
      'threadId': threadId,
      'peerUserId': peerUserId,
      'peerName': peerName,
      'peerPhone': peerPhone,
    });
    await flutterLocalNotificationsPlugin.show(
      _chatNotifId(threadId),
      peerName,
      text,
      const NotificationDetails(
        android: _chatAndroid,
        iOS: _darwinDetails,
        macOS: _darwinDetails,
      ),
      payload: payload,
    );
  }

  Future<void> scheduleMedicineReminder({
    required int id,
    required DateTime time,
    required String name,
    required String instructions,
    required String dosage,
  }) async {
    if (!SettingsStore.instance.medicineEnabled) return;
    final payload = jsonEncode({
      'type': 'medicine',
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
      const NotificationDetails(
        android: _medicineAndroid,
        iOS: _darwinDetails,
        macOS: _darwinDetails,
      ),
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

  int _callNotifId(String consultationId) =>
      900000000 + (consultationId.hashCode.abs() % 100000);

  int _chatNotifId(int threadId) => 800000000 + (threadId.abs() % 100000);

  Future<void> _speak(String text) async {
    try {
      await flutterTts.setLanguage(SettingsStore.instance.isHindi ? 'hi-IN' : 'en-IN');
      await flutterTts.setPitch(1.0);
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS Error: $e');
    }
  }
}
