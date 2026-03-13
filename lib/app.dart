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

class GraminHealthApp extends StatelessWidget {
  const GraminHealthApp({super.key});

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
      ],
      child: MaterialApp(
        title: 'Gramin Health Connect',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.login,
        onGenerateRoute: RouteGenerator.generateRoute,
      ),
    );
  }
}
