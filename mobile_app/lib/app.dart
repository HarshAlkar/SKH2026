import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'routes/route_generator.dart';
import 'providers/auth_provider.dart';
import 'providers/patient_provider.dart';
import 'providers/symptom_provider.dart';
import 'providers/consultation_provider.dart';
import 'providers/medicine_provider.dart';
import 'providers/alert_provider.dart';
import 'core/sync/sync_status.dart';
import 'core/emergency_comms/emergency_comms.dart';
import 'main.dart';

class VitalReachApp extends StatelessWidget {
  const VitalReachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => SymptomProvider()),
        ChangeNotifierProvider(create: (_) => ConsultationProvider()),
        ChangeNotifierProvider(create: (_) => MedicineProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
        ChangeNotifierProvider.value(value: SyncStatus.instance),
        ChangeNotifierProvider.value(value: EmergencyComms.instance),
      ],
      child: MaterialApp(
        title: 'VitalReach',
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: RouteGenerator.generateRoute,
      ),
    );
  }
}
