import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../features/asha_worker/screens/login_screen.dart';
import '../features/doctor/screens/doctor_login_screen.dart';
import '../features/asha_worker/screens/asha_dashboard.dart';
import '../features/doctor/screens/doctor_dashboard.dart';
import '../features/user/screens/user_dashboard_screen.dart';
import '../features/auth/screens/role_selection_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';

import '../features/user/screens/symptom_checker_screen.dart';
import '../features/user/screens/doctor_consult_screen.dart';
import '../features/user/screens/medicine_tracker_screen.dart';
import '../features/user/screens/add_medicine_screen.dart';
import '../features/user/screens/full_schedule_screen.dart';
import '../features/user/screens/medicine_call_screen.dart';
import '../features/user/screens/nearby_healthcare_screen.dart';
import '../features/user/screens/my_prescriptions_screen.dart';
import '../features/user/screens/emergency_help_screen.dart';

// ASHA Feature Screens
import '../features/reports/screens/village_health_report_screen.dart';
import '../features/patient/screens/village_patients_screen.dart';

import '../features/patient/screens/register_patient_screen.dart';
import '../features/asha_worker/screens/update_health_screen.dart';
import '../features/alerts/screens/risk_alert_screen.dart';
import '../features/doctor/screens/consult_doctor_screen.dart';
import '../features/health_records/screens/health_records_screen.dart';
import '../features/referral/screens/emergency_referral_screen.dart';
import '../features/referral/screens/referral_history_screen.dart';
import '../features/asha_worker/screens/asha_settings_screen.dart';
import '../features/visits/screens/village_visits_screen.dart';
import '../features/visits/screens/schedule_visit_screen.dart';

import '../features/patient/screens/patient_details_screen.dart';
import '../features/notifications/screens/notification_screen.dart';
import '../features/activity/screens/all_activity_screen.dart';
import '../features/activity/screens/activity_details_screen.dart';
import '../features/activity/models/activity_model.dart';
import '../features/asha_worker/widgets/asha_drawer.dart';
import '../core/widgets/common_appbar.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.roleSelection:
        return _fadeRoute(const RoleSelectionScreen());
      case AppRoutes.login:
      case AppRoutes.userLogin:
        return _fadeRoute(const LoginScreen());
      case AppRoutes.ashaLogin:
        return _fadeRoute(const AshaLoginScreen());
      case AppRoutes.doctorLogin:
        return _fadeRoute(const DoctorLoginScreen());
      case AppRoutes.register:
        return _fadeRoute(const RegisterScreen());
      case AppRoutes.userDashboard:
        return _fadeRoute(const UserDashboardScreen());
      case AppRoutes.ashaDashboard:
        return _fadeRoute(const AshaDashboard());
      case AppRoutes.doctorDashboard:
        return _fadeRoute(const DoctorDashboard());
      case AppRoutes.loginWithOtp:
        return _fadeRoute(_PlaceholderScreen(title: 'Login with OTP'));
      case AppRoutes.forgotPassword:
        return _fadeRoute(const ForgotPasswordScreen());
      case AppRoutes.symptomChecker:
        return _fadeRoute(const SymptomCheckerScreen());
      case AppRoutes.medicineTracker:
        return _fadeRoute(const MedicineTrackerScreen());
      case AppRoutes.addMedicine:
        return _fadeRoute(const AddMedicineScreen());
      case AppRoutes.medicineSchedule:
        return _fadeRoute(const FullScheduleScreen());
      case AppRoutes.medicineCall:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => MedicineReminderCallScreen(
            medicineId: args['id'],
            medicineName: args['name'],
            dosage: args['dosage'] ?? '',
            instructions: args['instructions'] ?? '',
          ),
        );
      case AppRoutes.nearbyClinics:
        return _fadeRoute(const NearbyHealthcareScreen());
      case AppRoutes.consultDoctor:
        return _fadeRoute(const DoctorConsultScreen());
      case AppRoutes.myPrescriptions:
        return _fadeRoute(const MyPrescriptionsScreen());
      case AppRoutes.healthTips:
        return _fadeRoute(_PlaceholderScreen(title: 'Health Tips'));
      case AppRoutes.emergencyHelp:
        return _fadeRoute(const EmergencyHelpScreen());
      case AppRoutes.settings:
        return _fadeRoute(_PlaceholderScreen(title: 'Settings'));
      case AppRoutes.profile:
        return _fadeRoute(_PlaceholderScreen(title: 'Profile'));

      // ASHA Worker portal routes
      case AppRoutes.villageHealthReport:
        return _fadeRoute(const VillageHealthReportScreen());
      case AppRoutes.villagePatients:
        return _fadeRoute(const VillagePatientsScreen());
      case AppRoutes.registerPatient:
        return _fadeRoute(const RegisterPatientScreen());
      case AppRoutes.editPatient:
        return _fadeRoute(AshaPlaceholderScreen(title: 'Edit Patient', route: settings.name!));
      case AppRoutes.updateHealth:
        return _fadeRoute(const UpdateHealthScreen());
      case AppRoutes.riskAlerts:
        return _fadeRoute(const RiskAlertScreen());
      case AppRoutes.ashaConsultDoctor:
        return _fadeRoute(const ConsultDoctorScreen());
      case AppRoutes.healthRecords:
        return _fadeRoute(const HealthRecordsScreen());
      case AppRoutes.villageVisits:
        return _fadeRoute(const VillageVisitsScreen());
      case AppRoutes.scheduleVisit:
        return _fadeRoute(const ScheduleVisitScreen());
      case AppRoutes.emergencyReferral:
        return _fadeRoute(const EmergencyReferralScreen());
      case AppRoutes.referralHistory:
        return _fadeRoute(const ReferralHistoryScreen());
      case AppRoutes.ashaSettings:
        return _fadeRoute(const AshaSettingsScreen());
      case AppRoutes.ashaNotifications:
        return _fadeRoute(const NotificationScreen());
      case AppRoutes.ashaAllActivity:
        return _fadeRoute(const AllActivityScreen());
      case AppRoutes.ashaActivityDetails:
        final activity = settings.arguments as ActivityModel;
        return _fadeRoute(ActivityDetailsScreen(activity: activity));
      case AppRoutes.ashaPatientDetails:
        return _fadeRoute(const PatientDetailsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }

  static PageRouteBuilder _fadeRoute(Widget child) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('This is the $title screen')),
    );
  }
}

class AshaPlaceholderScreen extends StatelessWidget {
  final String title;
  final String route;
  const AshaPlaceholderScreen({super.key, required this.title, required this.route});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: title),
      drawer: AshaDrawer(currentRoute: route),
      body: Center(child: Text('This is the $title screen')),
    );
  }
}
