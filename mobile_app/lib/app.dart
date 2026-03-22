import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/route_generator.dart';
import 'shared/providers/auth_provider.dart';
import 'shared/providers/patient_provider.dart';
import 'shared/providers/symptom_provider.dart';
import 'shared/providers/consultation_provider.dart';
import 'shared/providers/medicine_provider.dart';
import 'shared/providers/alert_provider.dart';
import 'shared/providers/voice_assistant_provider.dart';
import 'shared/providers/profile_provider.dart';
import 'features/user/screens/profile_screen.dart';
import 'features/user/screens/qr_scanner_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hs053/shared/providers/language_provider.dart';
import 'core/localization/app_localizations.dart';
import 'features/user/screens/settings_screen.dart';
import 'main.dart'; // Import to use navigatorKey

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
        ChangeNotifierProvider(create: (_) => VoiceAssistantProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      builder: (context, child) {
        final languageProvider = Provider.of<LanguageProvider>(context);
        return MaterialApp(
          title: 'VitalReach',
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          locale: languageProvider.appLocale,
          supportedLocales: const [
            Locale('en'),
            Locale('hi'),
            Locale('mr'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (locale, supportedLocales) {
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale?.languageCode) {
                return supportedLocale;
              }
            }
            return supportedLocales.first;
          },
          initialRoute: AppRoutes.roleSelection,
          routes: {
            AppRoutes.profile: (context) => const ProfileScreen(),
            AppRoutes.qrScanner: (context) => const QRScannerScreen(),
            AppRoutes.settings: (context) => const SettingsScreen(),
          },
          onGenerateRoute: RouteGenerator.generateRoute,
        );
      },
    );
  }
}
