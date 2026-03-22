import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'app.dart';
import 'core/services/storage_service.dart';
import 'core/services/alarm_service.dart';
import 'core/services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Timezones
  tz_data.initializeTimeZones();
  try {
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName.toString()));
  } catch (e) {
    debugPrint('Failed to initialize local timezone: $e');
    tz.setLocalLocation(tz.getLocation('UTC'));
  }

  // Initialize Services
  await StorageService.init();
  await AlarmService.init();
  await NotificationService().init();

  runApp(const VitalReachApp());
}
