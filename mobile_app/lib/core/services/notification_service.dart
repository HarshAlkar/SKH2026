import 'dart:convert';
import 'package:flutter/material.dart';
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
    presentBanner: true,
    presentList: true,
    interruptionLevel: InterruptionLevel.timeSensitive,
  );

  static const DarwinNotificationDetails _callDarwin = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    presentBanner: true,
    presentList: true,
    interruptionLevel: InterruptionLevel.critical,
  );

  Future<void> init() async {
    tzdata.initializeTimeZones();
    _configureLocalTimezone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestProvisionalPermission: false,
      requestCriticalPermission: false,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
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

    try {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final androidGranted = await androidPlugin?.requestNotificationsPermission();
      debugPrint('[MedicineReminder] Android notification permission: $androidGranted');
    } catch (e) {
      debugPrint('[MedicineReminder] Android permission check error: $e');
    }

    try {
      final iosPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final iosGranted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[MedicineReminder] iOS notification permission granted: $iosGranted');
    } catch (e) {
      debugPrint('[MedicineReminder] iOS permission check error: $e');
    }

    final launch = await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      final payload = launch?.notificationResponse?.payload;
      if (payload != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => handlePayload(payload));
      }
    }

    debugPrint('[MedicineReminder] NotificationService initialized successfully');
  }

  void _configureLocalTimezone() {
    try {
      final now = DateTime.now();
      final offsetMs = now.timeZoneOffset.inMilliseconds;
      final tzName = now.timeZoneName;

      // 1. Try matching by exact name if exists in database
      if (tz.timeZoneDatabase.locations.containsKey(tzName)) {
        tz.setLocalLocation(tz.getLocation(tzName));
        return;
      }

      // 2. Try matching by UTC offset
      for (final location in tz.timeZoneDatabase.locations.values) {
        if (location.currentTimeZone.offset == offsetMs) {
          tz.setLocalLocation(location);
          return;
        }
      }

      // 3. Fallback
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    } catch (e) {
      debugPrint('[MedicineReminder] Timezone config warning: $e');
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pending = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      debugPrint('[MedicineReminder] Pending notifications count: ${pending.length}');
      for (var p in pending) {
        debugPrint('[MedicineReminder] Pending item: ID=${p.id}, Title="${p.title}", Body="${p.body}"');
      }
      return pending;
    } catch (e) {
      debugPrint('[MedicineReminder] Error fetching pending notifications: $e');
      return [];
    }
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

      if (type == 'medicine') {
        final dateStr = map['date']?.toString();
        DateTime? targetDate;
        if (dateStr != null && dateStr.isNotEmpty) {
          try {
            targetDate = DateTime.parse(dateStr);
          } catch (_) {}
        }
        nav.pushNamed(AppRoutes.medicineTracker, arguments: targetDate);
        return;
      }
    } catch (e) {
      debugPrint('[MedicineReminder] Notification payload error: $e');
    }
  }

  Future<void> showMedicineReminder(
    int id,
    String name,
    String instructions,
    String dosage, {
    String? date,
  }) async {
    if (!SettingsStore.instance.medicineEnabled) return;
    final payload = jsonEncode({
      'type': 'medicine',
      'id': id,
      'name': name,
      'instructions': instructions,
      'dosage': dosage,
      'date': date,
    });

    final bodyText = dosage.isNotEmpty
        ? "It's time to take $name — $dosage."
        : "It's time to take $name.";

    await flutterLocalNotificationsPlugin.show(
      id % 2147483647,
      '💊 Medicine Reminder',
      bodyText,
      const NotificationDetails(
        android: _medicineAndroid,
        iOS: _darwinDetails,
        macOS: _darwinDetails,
      ),
      payload: payload,
    );

    await _speak(
      'Attention: It is time to take your medicine $name. Dawai lene ka samay ho gaya hai.',
    );
  }

  Future<void> scheduleMedicineScheduleReminders({
    required int id,
    required String name,
    required String dosage,
    required String frequency,
    required String startDateStr,
    required String endDateStr,
    required String reminderTimeStr,
    required String instructions,
  }) async {
    if (!SettingsStore.instance.medicineEnabled) return;

    // 1. Cancel previous notifications for this medicine
    await cancelMedicineReminders(id);

    // 2. Parse Time
    final time = _parseReminderTime(reminderTimeStr);
    if (time == null) {
      debugPrint('[MedicineReminder] Cannot schedule: invalid time string "$reminderTimeStr"');
      return;
    }

    // 3. Parse Start Date
    DateTime startDate;
    try {
      startDate = DateTime.parse(startDateStr);
    } catch (_) {
      startDate = DateTime.now();
    }

    final freq = frequency.trim().toLowerCase();
    final now = DateTime.now();

    debugPrint('[MedicineReminder] Scheduling $name (ID: $id, Freq: $frequency, Time: $reminderTimeStr, StartDate: $startDateStr)...');

    // Case A: ONE-TIME MEDICINE
    if (freq == 'once' || freq == 'one-time' || freq == 'single') {
      final scheduledDt = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        time.hour,
        time.minute,
      );
      final scheduledTz = tz.TZDateTime(
        tz.local,
        scheduledDt.year,
        scheduledDt.month,
        scheduledDt.day,
        scheduledDt.hour,
        scheduledDt.minute,
      );

      if (scheduledDt.isAfter(now)) {
        final notifId = _generateNotifId(id, 0);
        final payload = jsonEncode({
          'type': 'medicine',
          'id': id,
          'name': name,
          'dosage': dosage,
          'instructions': instructions,
          'date': startDateStr,
        });

        final bodyText = dosage.isNotEmpty
            ? "It's time to take $name — $dosage."
            : "It's time to take $name.";

        await flutterLocalNotificationsPlugin.zonedSchedule(
          notifId,
          '💊 Medicine Reminder',
          bodyText,
          scheduledTz,
          const NotificationDetails(
            android: _medicineAndroid,
            iOS: _darwinDetails,
            macOS: _darwinDetails,
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: null, // Exact one-shot date/time schedule
          payload: payload,
        );
        debugPrint('[MedicineReminder] Scheduled successfully: $name on $scheduledTz (ID: $notifId)');
      } else {
        debugPrint('[MedicineReminder] Skipped: $scheduledDt is in the past compared to current time $now');
      }

      await getPendingNotifications();
      return;
    }

    // Case B: DAILY RECURRING MEDICINE
    DateTime endDate;
    try {
      endDate = DateTime.parse(endDateStr);
    } catch (_) {
      endDate = startDate.add(const Duration(days: 30));
    }

    // Ensure we don't schedule beyond end date or beyond 60 days
    final maxEndDate = endDate.isAfter(startDate.add(const Duration(days: 60)))
        ? startDate.add(const Duration(days: 60))
        : endDate;

    int dayOffset = 0;
    DateTime currentDay = startDate;
    int scheduledCount = 0;

    while (!currentDay.isAfter(maxEndDate)) {
      final scheduledDt = DateTime(
        currentDay.year,
        currentDay.month,
        currentDay.day,
        time.hour,
        time.minute,
      );
      final scheduledTz = tz.TZDateTime(
        tz.local,
        scheduledDt.year,
        scheduledDt.month,
        scheduledDt.day,
        scheduledDt.hour,
        scheduledDt.minute,
      );

      if (scheduledDt.isAfter(now)) {
        final notifId = _generateNotifId(id, dayOffset);
        final dateFormatted = "${currentDay.year.toString().padLeft(4, '0')}-${currentDay.month.toString().padLeft(2, '0')}-${currentDay.day.toString().padLeft(2, '0')}";
        final payload = jsonEncode({
          'type': 'medicine',
          'id': id,
          'name': name,
          'dosage': dosage,
          'instructions': instructions,
          'date': dateFormatted,
        });

        final bodyText = dosage.isNotEmpty
            ? "It's time to take $name — $dosage."
            : "It's time to take $name.";

        await flutterLocalNotificationsPlugin.zonedSchedule(
          notifId,
          '💊 Medicine Reminder',
          bodyText,
          scheduledTz,
          const NotificationDetails(
            android: _medicineAndroid,
            iOS: _darwinDetails,
            macOS: _darwinDetails,
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: null, // Specific exact day
          payload: payload,
        );
        scheduledCount++;
      }

      currentDay = currentDay.add(const Duration(days: 1));
      dayOffset++;
    }
    debugPrint('[MedicineReminder] Scheduled successfully: $scheduledCount DAILY notifications for $name from $startDateStr to $endDateStr');
    await getPendingNotifications();
  }

  Future<void> cancelMedicineReminders(int id) async {
    for (int offset = 0; offset < 65; offset++) {
      final notifId = _generateNotifId(id, offset);
      await flutterLocalNotificationsPlugin.cancel(notifId);
    }
    await flutterLocalNotificationsPlugin.cancel(id % 2147483647);
  }

  int _generateNotifId(int medicineId, int dayOffset) {
    return ((medicineId.abs() % 10000) * 100 + (dayOffset % 100)) % 2147483647;
  }

  TimeOfDay? _parseReminderTime(String timeStr) {
    try {
      // Normalize Unicode spaces (like \u202F from iOS TimeOfDay format)
      final cleaned = timeStr.trim().replaceAll('\u202F', ' ').replaceAll('\u00A0', ' ');
      final isPm = cleaned.toLowerCase().contains('pm');
      final isAm = cleaned.toLowerCase().contains('am');
      
      // Match 1 or 2 digits followed by colon/dot and 2 digits
      final match = RegExp(r'(\d{1,2})[:.](\d{1,2})').firstMatch(cleaned);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        int minute = int.parse(match.group(2)!);
        if (isPm && hour < 12) hour += 12;
        if (isAm && hour == 12) hour = 0;
        if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
    } catch (e) {
      debugPrint('[MedicineReminder] Time parsing error for "$timeStr": $e');
    }
    return null;
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

  Future<void> showAppointmentConfirmation({
    required String doctorName,
    required String date,
    required String time,
    required String specialty,
  }) async {
    final payload = jsonEncode({
      'type': 'appointment',
      'doctorName': doctorName,
      'date': date,
      'time': time,
    });

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🗓️ Appointment Confirmed',
      'Your consultation with $doctorName ($specialty) is scheduled for $date at $time.',
      const NotificationDetails(
        android: _medicineAndroid,
        iOS: _darwinDetails,
        macOS: _darwinDetails,
      ),
      payload: payload,
    );
  }

  Future<void> scheduleAppointmentReminder({
    required int appointmentId,
    required DateTime appointmentDateTime,
    required String doctorName,
    required String specialty,
  }) async {
    final payload = jsonEncode({
      'type': 'appointment_reminder',
      'appointmentId': appointmentId,
      'doctorName': doctorName,
    });

    final scheduled = tz.TZDateTime.from(appointmentDateTime, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (scheduled.isAfter(now)) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        700000000 + (appointmentId % 100000),
        '🗓️ Upcoming Doctor Appointment',
        'Reminder: You have a scheduled appointment with $doctorName ($specialty) today.',
        scheduled,
        const NotificationDetails(
          android: _medicineAndroid,
          iOS: _darwinDetails,
          macOS: _darwinDetails,
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    }
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
