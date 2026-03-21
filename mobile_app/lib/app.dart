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
import 'core/providers/settings_provider.dart';
import 'main.dart'; // Import to use navigatorKey

class GraminHealthApp extends StatelessWidget {
  const GraminHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => SymptomProvider()),
        ChangeNotifierProvider(create: (_) => ConsultationProvider()),
        ChangeNotifierProvider(create: (_) => MedicineProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'VitalReach',
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            locale: settings.locale,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(settings.fontSizeMultiplier),
                ),
                child: child!,
              );
            },
            initialRoute: AppRoutes.roleSelection,
            onGenerateRoute: RouteGenerator.generateRoute,
          );
        },
      ),
    );
  }
}
