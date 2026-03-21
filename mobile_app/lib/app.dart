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
import 'core/services/language_manager.dart';
import 'providers/realtime_provider.dart';
import 'core/keys/navigator_key.dart';

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
        ChangeNotifierProvider(create: (_) => LanguageManager()),
        ChangeNotifierProvider(create: (_) => RealtimeProvider()),
      ],
      child: MaterialApp(
        title: 'VitalReach',
        navigatorKey: navigatorKey, // Set the key here
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.roleSelection,
        onGenerateRoute: RouteGenerator.generateRoute,
      ),
    );
  }
}
