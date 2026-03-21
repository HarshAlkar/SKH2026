import 'package:flutter/material.dart';
import 'app.dart';
import 'core/services/storage_service.dart';
import 'core/services/alarm_service.dart';
import 'core/services/notification_service.dart';

import 'core/keys/navigator_key.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Services
  await StorageService.init();
  await AlarmService.init();
  await NotificationService().init();

  runApp(const VitalReachApp());
}
