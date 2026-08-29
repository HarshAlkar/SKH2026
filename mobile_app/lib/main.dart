import 'dart:async';
import 'package:flutter/material.dart';
import 'app.dart';
import 'core/services/storage_service.dart';
import 'core/services/alarm_service.dart';
import 'core/services/notification_service.dart';
import 'core/sync/sync_service.dart';
import 'core/emergency_comms/emergency_comms.dart';
import 'core/emergency_comms/emergency_alert_host.dart';
import 'core/recovery/disaster_recovery_service.dart';
import 'core/recovery/snapshot_manager.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await StorageService.init();
  try {
    await AlarmService.init();
  } catch (e, st) {
    debugPrint('AlarmService.init failed: $e\n$st');
  }
  try {
    await NotificationService().init();
  } catch (e, st) {
    debugPrint('NotificationService.init failed: $e\n$st');
  }
  try {
    await SyncService.instance.start();
  } catch (e, st) {
    debugPrint('SyncService.start failed: $e\n$st');
  }
  try {
    await EmergencyComms.instance.initialize();
  } catch (e, st) {
    debugPrint('EmergencyComms.init failed: $e\n$st');
  }
  EmergencyAlertHost.instance.start();

  try {
    final healthy = await DisasterRecoveryService.instance.checkHealth();
    if (!healthy) {
      debugPrint('[DisasterRecovery] Integrity check failed on startup. Triggering automatic recovery...');
      await DisasterRecoveryService.instance.executeDisasterRecovery();
    } else {
      unawaited(SnapshotManager.instance.createSnapshot(reason: 'app_launch_baseline'));
    }
  } catch (e, st) {
    debugPrint('DisasterRecovery startup init failed: $e\n$st');
  }

  runApp(const VitalReachApp());
}
