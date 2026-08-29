import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:hs053/models/medicine_model.dart';
import 'package:hs053/core/services/notification_service.dart';
import 'package:hs053/core/services/storage_service.dart';
import 'package:hs053/features/alerts/models/alert_model.dart';

class FakeAndroidNotifications extends AndroidFlutterLocalNotificationsPlugin {
  final List<Map<String, dynamic>> scheduledNotifications = [];
  final List<int> cancelledNotifications = [];

  @override
  Future<bool> initialize(
    AndroidInitializationSettings initializationSettings, {
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
        onDidReceiveBackgroundNotificationResponse,
  }) async {
    return true;
  }

  @override
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    tz.TZDateTime scheduledDate,
    AndroidNotificationDetails? notificationDetails, {
    required AndroidScheduleMode scheduleMode,
    DateTimeComponents? matchDateTimeComponents,
    String? payload,
    UILocalNotificationDateInterpretation
        uiLocalNotificationDateInterpretation =
        UILocalNotificationDateInterpretation.absoluteTime,
  }) async {
    scheduledNotifications.add({
      'id': id,
      'title': title,
      'body': body,
      'scheduledDate': scheduledDate,
      'payload': payload,
    });
  }

  @override
  Future<void> cancel(int id, {String? tag}) async {
    cancelledNotifications.add(id);
    scheduledNotifications.removeWhere((n) => n['id'] == id);
  }

  @override
  Future<void> cancelAll() async {
    scheduledNotifications.clear();
  }

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    return scheduledNotifications.map((n) {
      return PendingNotificationRequest(
        n['id'] as int,
        n['title'] as String?,
        n['body'] as String?,
        n['payload'] as String?,
      );
    }).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAndroidNotifications mockPlatform;

  setUpAll(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    mockPlatform = FakeAndroidNotifications();
    FlutterLocalNotificationsPlatform.instance = mockPlatform;

    SharedPreferences.setMockInitialValues({'notif_medicine': true});
    await StorageService.init();

    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  });

  tearDownAll(() {
    debugDefaultTargetPlatformOverride = null;
  });

  setUp(() {
    mockPlatform.scheduledNotifications.clear();
    mockPlatform.cancelledNotifications.clear();
  });

  group('Medicine Model Scheduling & Date Filter Tests', () {
    test('Once medicine is scheduled only for its exact startDate', () {
      final medicine = MedicineModel(
        id: 101,
        medicineName: 'Paracetamol',
        dosage: '500mg',
        frequency: 'Once',
        startDate: '2026-09-01',
        endDate: '2026-09-01',
        reminderTime: '08:00 AM',
        instructions: 'After food',
        createdAt: DateTime(2026, 8, 28),
      );

      // Verify date filter matching
      expect(medicine.isScheduledForDate(DateTime(2026, 9, 1)), isTrue);
      expect(medicine.isScheduledForDate(DateTime(2026, 9, 2)), isFalse);
      expect(medicine.isScheduledForDate(DateTime(2026, 8, 31)), isFalse);
    });

    test('Daily medicine is scheduled for all dates in configured range', () {
      final medicine = MedicineModel(
        id: 102,
        medicineName: 'Amoxicillin',
        dosage: '250mg',
        frequency: 'Daily',
        startDate: '2026-09-01',
        endDate: '2026-09-05',
        reminderTime: '09:00 PM',
        instructions: 'With water',
        createdAt: DateTime(2026, 8, 28),
      );

      // Verify date range matching
      expect(medicine.isScheduledForDate(DateTime(2026, 8, 31)), isFalse);
      expect(medicine.isScheduledForDate(DateTime(2026, 9, 1)), isTrue);
      expect(medicine.isScheduledForDate(DateTime(2026, 9, 3)), isTrue);
      expect(medicine.isScheduledForDate(DateTime(2026, 9, 5)), isTrue);
      expect(medicine.isScheduledForDate(DateTime(2026, 9, 6)), isFalse);
    });
  });

  group('NotificationService Scheduling & Cancellation Tests', () {
    test('Once medicine -> schedules exactly one notification on actual scheduled date (not DateTime.now())', () async {
      final notifService = NotificationService();

      final targetDate = '2026-10-15';
      await notifService.scheduleMedicineScheduleReminders(
        id: 301,
        name: 'Dolo 650',
        dosage: '1 Tab',
        frequency: 'Once',
        startDateStr: targetDate,
        endDateStr: targetDate,
        reminderTimeStr: '10:00 AM',
        instructions: 'After breakfast',
      );

      // 1. Must schedule exactly ONE notification
      expect(mockPlatform.scheduledNotifications.length, equals(1));

      final scheduled = mockPlatform.scheduledNotifications.first;
      final scheduledDate = scheduled['scheduledDate'] as tz.TZDateTime;
      
      // 2. Must use the actual scheduled medicine date (2026-10-15), not today's date
      expect(scheduledDate.year, equals(2026));
      expect(scheduledDate.month, equals(10));
      expect(scheduledDate.day, equals(15));
      expect(scheduledDate.hour, equals(10));
      expect(scheduledDate.minute, equals(0));

      final payload = jsonDecode(scheduled['payload']);
      expect(payload['name'], equals('Dolo 650'));
      expect(payload['date'], equals('2026-10-15'));
    });

    test('Daily medicine -> schedules notifications across configured date range', () async {
      final notifService = NotificationService();

      // 4 days range: 2026-10-01 to 2026-10-04
      await notifService.scheduleMedicineScheduleReminders(
        id: 401,
        name: 'Metformin',
        dosage: '500mg',
        frequency: 'Daily',
        startDateStr: '2026-10-01',
        endDateStr: '2026-10-04',
        reminderTimeStr: '08:00 PM',
        instructions: 'After dinner',
      );

      // Must schedule exactly 4 notifications (Oct 1, 2, 3, 4)
      expect(mockPlatform.scheduledNotifications.length, equals(4));

      final dates = mockPlatform.scheduledNotifications.map((n) {
        final dt = n['scheduledDate'] as tz.TZDateTime;
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      }).toList();

      expect(dates, containsAll(['2026-10-01', '2026-10-02', '2026-10-03', '2026-10-04']));
    });

    test('Editing medicine -> cancels old notifications and schedules new ones', () async {
      final notifService = NotificationService();

      // Initial schedule: 3 days
      await notifService.scheduleMedicineScheduleReminders(
        id: 501,
        name: 'Antibiotic A',
        dosage: '100mg',
        frequency: 'Daily',
        startDateStr: '2026-10-01',
        endDateStr: '2026-10-03',
        reminderTimeStr: '09:00 AM',
        instructions: 'Twice daily',
      );

      expect(mockPlatform.scheduledNotifications.length, equals(3));
      mockPlatform.cancelledNotifications.clear();

      // Edit medicine: change to Once on 2026-10-10 at 02:00 PM
      await notifService.scheduleMedicineScheduleReminders(
        id: 501,
        name: 'Antibiotic A (Updated)',
        dosage: '200mg',
        frequency: 'Once',
        startDateStr: '2026-10-10',
        endDateStr: '2026-10-10',
        reminderTimeStr: '02:00 PM',
        instructions: 'After lunch',
      );

      // Old notifications were cancelled (at least 65 offsets for id 501 checked)
      expect(mockPlatform.cancelledNotifications.isNotEmpty, isTrue);

      // New notification scheduled
      expect(mockPlatform.scheduledNotifications.length, equals(1));
      final updatedNotif = mockPlatform.scheduledNotifications.first;
      final dt = updatedNotif['scheduledDate'] as tz.TZDateTime;
      expect(dt.year, equals(2026));
      expect(dt.month, equals(10));
      expect(dt.day, equals(10));
      expect(dt.hour, equals(14)); // 2 PM -> 14:00
      expect(dt.minute, equals(0));
    });

    test('NDBF Once medicine: edit time from 2:07 PM to 5:00 PM preserves Aug 30 date and reschedules', () async {
      final notifService = NotificationService();

      // Initial add: Aug 30 at 2:07 PM
      await notifService.scheduleMedicineScheduleReminders(
        id: 701,
        name: 'NDBF',
        dosage: 'VVS',
        frequency: 'Once',
        startDateStr: '2026-08-30',
        endDateStr: '2026-08-30',
        reminderTimeStr: '2:07 PM',
        instructions: 'Take once',
      );

      expect(mockPlatform.scheduledNotifications.length, equals(1));
      final initialNotif = mockPlatform.scheduledNotifications.first;
      final initDt = initialNotif['scheduledDate'] as tz.TZDateTime;
      expect(initDt.year, equals(2026));
      expect(initDt.month, equals(8));
      expect(initDt.day, equals(30));
      expect(initDt.hour, equals(14));
      expect(initDt.minute, equals(7));

      mockPlatform.cancelledNotifications.clear();

      // Edit: Change time to 5:00 PM
      await notifService.scheduleMedicineScheduleReminders(
        id: 701,
        name: 'NDBF',
        dosage: 'VVS',
        frequency: 'Once',
        startDateStr: '2026-08-30',
        endDateStr: '2026-08-30',
        reminderTimeStr: '5:00 PM',
        instructions: 'Take once',
      );

      // Old notification cancelled
      expect(mockPlatform.cancelledNotifications.isNotEmpty, isTrue);

      // New notification scheduled at 5:00 PM on Aug 30
      expect(mockPlatform.scheduledNotifications.length, equals(1));
      final updatedNotif = mockPlatform.scheduledNotifications.first;
      final updatedDt = updatedNotif['scheduledDate'] as tz.TZDateTime;
      expect(updatedDt.year, equals(2026));
      expect(updatedDt.month, equals(8));
      expect(updatedDt.day, equals(30));
      expect(updatedDt.hour, equals(17)); // 5 PM -> 17:00
      expect(updatedDt.minute, equals(0));
    });

    test('Test Daily Medicine: edit time from 10:00 AM to 11:00 AM preserves Aug 30 - Sep 3 range', () async {
      final notifService = NotificationService();

      // Initial add: Aug 30 to Sep 3 at 10:00 AM (5 days)
      await notifService.scheduleMedicineScheduleReminders(
        id: 801,
        name: 'Test Daily Medicine',
        dosage: '1 Tab',
        frequency: 'Daily',
        startDateStr: '2026-08-30',
        endDateStr: '2026-09-03',
        reminderTimeStr: '10:00 AM',
        instructions: 'Daily morning',
      );

      expect(mockPlatform.scheduledNotifications.length, equals(5));
      mockPlatform.cancelledNotifications.clear();

      // Edit: Change time to 11:00 AM
      await notifService.scheduleMedicineScheduleReminders(
        id: 801,
        name: 'Test Daily Medicine',
        dosage: '1 Tab',
        frequency: 'Daily',
        startDateStr: '2026-08-30',
        endDateStr: '2026-09-03',
        reminderTimeStr: '11:00 AM',
        instructions: 'Daily morning',
      );

      // Old notifications cancelled
      expect(mockPlatform.cancelledNotifications.isNotEmpty, isTrue);

      // New notifications: 5 notifications at 11:00 AM across Aug 30 - Sep 3
      expect(mockPlatform.scheduledNotifications.length, equals(5));
      for (final n in mockPlatform.scheduledNotifications) {
        final dt = n['scheduledDate'] as tz.TZDateTime;
        expect(dt.hour, equals(11));
        expect(dt.minute, equals(0));
      }
    });

    test('Unicode narrow no-break space in time string (e.g. iOS TimeOfDay format) schedules correctly', () async {
      final notifService = NotificationService();

      // "2:07\u202FPM" (contains \u202F used on iOS)
      await notifService.scheduleMedicineScheduleReminders(
        id: 999,
        name: 'Unicode Time Med',
        dosage: '1 Tab',
        frequency: 'Once',
        startDateStr: '2026-10-15',
        endDateStr: '2026-10-15',
        reminderTimeStr: '2:07\u202FPM',
        instructions: 'Test',
      );

      expect(mockPlatform.scheduledNotifications.length, equals(1));
      final notif = mockPlatform.scheduledNotifications.first;
      final dt = notif['scheduledDate'] as tz.TZDateTime;
      expect(dt.hour, equals(14));
      expect(dt.minute, equals(7));
    });

    test('Deleting medicine -> cancels all scheduled notifications for that medicine ID', () async {
      final notifService = NotificationService();

      // Initial add
      await notifService.scheduleMedicineScheduleReminders(
        id: 901,
        name: 'Medicine To Delete',
        dosage: '1 Tab',
        frequency: 'Daily',
        startDateStr: '2026-08-30',
        endDateStr: '2026-09-02',
        reminderTimeStr: '10:00 AM',
        instructions: 'Test',
      );

      expect(mockPlatform.scheduledNotifications.length, equals(4));

      // Cancel
      await notifService.cancelMedicineReminders(901);
      expect(mockPlatform.scheduledNotifications.isEmpty, isTrue);
      expect(mockPlatform.cancelledNotifications.isNotEmpty, isTrue);
    });
  });

  group('In-App Notification & History Tests', () {
    test('AlertModel.fromMedicineReminder creates valid in-app notification record', () {
      final alert = AlertModel.fromMedicineReminder(
        medicineId: 101,
        medicineName: 'NDBF',
        dosage: 'VVS',
        reminderTime: '2:07 PM',
        scheduledDate: '2026-08-30',
        occurrenceTime: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      expect(alert.isMedicineReminder, isTrue);
      expect(alert.medicineName, equals('NDBF'));
      expect(alert.reminderTime, equals('2:07 PM'));
      expect(alert.scheduledDate, equals('2026-08-30'));
      expect(alert.alertType, equals('💊 Medicine Reminder'));
      expect(alert.description, contains('NDBF'));
      expect(alert.description, contains('VVS'));
      expect(alert.timestamp, contains('mins ago'));
    });

    test('relativeTime handles Just now, mins ago, and hours ago', () {
      expect(relativeTime(DateTime.now()), equals('Just now'));
      expect(relativeTime(DateTime.now().subtract(const Duration(minutes: 2))), equals('2 mins ago'));
      expect(relativeTime(DateTime.now().subtract(const Duration(hours: 3))), equals('3 hours ago'));
    });
  });
}
