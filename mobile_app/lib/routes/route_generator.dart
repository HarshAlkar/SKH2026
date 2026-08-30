import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../features/asha_worker/screens/login_screen.dart';
import '../features/asha_worker/screens/asha_register_screen.dart';
import '../features/doctor/screens/doctor_login_screen.dart';
import '../features/doctor/screens/doctor_register.dart';
import '../features/asha_worker/screens/asha_verification_screen.dart';
import '../features/doctor/screens/doctor_verification_screen.dart';
import '../features/patient/screens/patient_login_screen.dart';
import '../features/patient/screens/patient_register_screen.dart';
import '../features/asha_worker/screens/asha_dashboard.dart';
import '../features/doctor/screens/doctor_dashboard.dart';
import '../features/user/screens/user_dashboard_screen.dart';
import '../features/auth/screens/role_selection_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/otp_verification_screen.dart';
import '../features/auth/screens/session_splash_screen.dart';

import '../features/user/screens/symptom_checker_screen.dart';
import '../features/one_health/screens/one_health_hub_screen.dart';
import '../features/one_health/screens/livestock_screening_screen.dart';
import '../features/one_health/screens/child_development_screen.dart';
import '../features/trustshield/screens/verify_health_information_screen.dart';
import '../features/user/screens/doctor_consult_screen.dart';
import '../features/user/screens/medicine_tracker_screen.dart';
import '../features/user/screens/add_medicine_screen.dart';
import '../features/user/screens/full_schedule_screen.dart';
import '../features/user/screens/medicine_call_screen.dart';
import '../features/user/screens/nearby_healthcare_screen.dart';
import '../features/user/screens/my_prescriptions_screen.dart';
import '../features/user/screens/emergency_help_screen.dart';
import '../features/user/screens/health_tips_screen.dart';
import '../features/user/screens/patient_alerts_screen.dart';
import '../features/user/screens/book_appointment_screen.dart';
import '../features/user/screens/patient_appointments_screen.dart';

// ASHA Feature Screens
import '../features/reports/screens/village_health_report_screen.dart';
import '../features/patient/screens/village_patients_screen.dart';

import '../features/patient/screens/register_patient_screen.dart';
import '../features/asha_worker/screens/update_health_screen.dart';
import '../features/alerts/screens/risk_alert_screen.dart';
import '../features/doctor/screens/consult_doctor_screen.dart';
import '../features/health_records/screens/health_records_screen.dart';
import '../features/visits/screens/village_visits_screen.dart';
import '../features/visits/screens/schedule_visit_screen.dart';
import '../features/asha_worker/screens/registered_doctors_screen.dart';
import '../features/referral/screens/emergency_referral_screen.dart';
import '../features/referral/screens/referral_history_screen.dart';
import '../features/patient/screens/edit_patient_screen.dart';
import '../features/patient/models/patient_model.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/settings_screen.dart';
import '../features/asha_worker/screens/asha_call_screen.dart';
import '../features/user/screens/asha_workers_screen.dart';
import '../features/chat/screens/chat_inbox_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/user/screens/call_history_screen.dart';
import '../features/user/screens/incoming_call_screen.dart';
import '../features/stock/screens/medicine_stock_screen.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _fadeRoute(const SessionSplashScreen());
      case AppRoutes.roleSelection:
        return _fadeRoute(const RoleSelectionScreen());
      case AppRoutes.login:
      case AppRoutes.userLogin:
        return _fadeRoute(const PatientLoginScreen());
      case AppRoutes.userRegister:
        return _fadeRoute(const PatientRegisterScreen());
      case AppRoutes.ashaLogin:
        return _fadeRoute(const AshaLoginScreen());
      case AppRoutes.ashaRegister:
        return _fadeRoute(const AshaRegisterScreen());
      case AppRoutes.doctorLogin:
        return _fadeRoute(const DoctorLoginScreen());
      case AppRoutes.doctorRegister:
        return _fadeRoute(const DoctorRegisterScreen());
      case AppRoutes.doctorVerification:
        return _fadeRoute(const DoctorVerificationScreen());
      case AppRoutes.ashaVerification:
        return _fadeRoute(const AshaVerificationScreen());
      case AppRoutes.userDashboard:
        return _fadeRoute(const UserDashboardScreen());
      case AppRoutes.ashaDashboard:
        return _fadeRoute(const AshaDashboard());
      case AppRoutes.doctorDashboard:
        return _fadeRoute(const DoctorDashboard());
      case AppRoutes.loginWithOtp:
        final args = (settings.arguments as Map?) ?? {};
        return _fadeRoute(OtpVerificationScreen(
          phoneNumber: args['phoneNumber']?.toString() ?? '',
          role: args['role']?.toString() ?? 'user',
          isForgotPassword: args['isForgotPassword'] == true,
          debugOtp: args['debugOtp']?.toString(),
        ));
      case AppRoutes.forgotPassword:
        return _fadeRoute(const ForgotPasswordScreen());
      case AppRoutes.symptomChecker:
        return _fadeRoute(const SymptomCheckerScreen());
      case AppRoutes.oneHealthHub:
        return _fadeRoute(const OneHealthHubScreen());
      case AppRoutes.livestockScreening:
        return _fadeRoute(const LivestockScreeningScreen());
      case AppRoutes.childDevelopment:
        return _fadeRoute(const ChildDevelopmentScreen());
      case AppRoutes.verifyHealthInfo:
      case AppRoutes.trustShieldDemo:
        return _fadeRoute(const VerifyHealthInformationScreen());
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
      case AppRoutes.medicineStock:
      case AppRoutes.medicineAvailability:
        return _fadeRoute(const MedicineStockScreen(canUpdate: false));
      case AppRoutes.updateStock:
        return _fadeRoute(const MedicineStockScreen(canUpdate: true));
      case AppRoutes.consultDoctor:
        return _fadeRoute(const DoctorConsultScreen());
      case AppRoutes.myPrescriptions:
        return _fadeRoute(const MyPrescriptionsScreen());
      case AppRoutes.healthTips:
        return _fadeRoute(const HealthTipsScreen());
      case AppRoutes.bookAppointment:
        final args = settings.arguments;
        String? initialSymptoms;
        if (args is Map) {
          initialSymptoms = args['symptoms']?.toString();
        }
        return _fadeRoute(
          BookAppointmentScreen(initialSymptoms: initialSymptoms),
        );
      case AppRoutes.patientAppointments:
        return _fadeRoute(const PatientAppointmentsScreen());
      case AppRoutes.patientAlerts:
        return _fadeRoute(const PatientAlertsScreen());
      case AppRoutes.emergencyHelp:
        return _fadeRoute(const EmergencyHelpScreen());
      case AppRoutes.settings:
      case AppRoutes.ashaSettings:
      case AppRoutes.doctorSettings:
        return _fadeRoute(const SettingsScreen());
      case AppRoutes.profile:
        return _fadeRoute(const ProfileScreen());

      // ASHA Worker portal routes
      case AppRoutes.villageHealthReport:
        return _fadeRoute(const VillageHealthReportScreen());
      case AppRoutes.villagePatients:
        return _fadeRoute(const VillagePatientsScreen());
      case AppRoutes.registerPatient:
        return _fadeRoute(const RegisterPatientScreen());
      case AppRoutes.editPatient:
        final patient = settings.arguments;
        if (patient is PatientModel) {
          return _fadeRoute(EditPatientScreen(patient: patient));
        }
        return _fadeRoute(const _PlaceholderScreen(title: 'Edit Patient'));
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
      case AppRoutes.registeredDoctors:
        return _fadeRoute(const RegisteredDoctorsScreen());
      case AppRoutes.emergencyReferral:
        return _fadeRoute(const EmergencyReferralScreen());
      case AppRoutes.referralHistory:
        return _fadeRoute(const ReferralHistoryScreen());
      case AppRoutes.ashaCall:
        return _fadeRoute(const AshaCallScreen());
      case AppRoutes.ashaWorkers:
        return _fadeRoute(const AshaWorkersScreen());
      case AppRoutes.chatInbox:
        return _fadeRoute(const ChatInboxScreen());
      case AppRoutes.callHistory:
        return _fadeRoute(const CallHistoryScreen());
      case AppRoutes.incomingCall:
        final args = (settings.arguments as Map?) ?? {};
        return MaterialPageRoute(
          builder: (_) => IncomingCallScreen(
            consultationId: args['consultationId']?.toString() ?? '',
            callerName: args['callerName']?.toString() ?? 'Caller',
            callType: args['callType']?.toString() ?? 'VIDEO',
            callerUserId: int.tryParse(args['callerUserId']?.toString() ?? ''),
          ),
        );
      case AppRoutes.chatThread:
        final args = (settings.arguments as Map?) ?? {};
        final peerId = int.tryParse(args['peerUserId']?.toString() ?? '') ?? 0;
        return MaterialPageRoute(
          builder: (_) => ChatScreen(
            peerUserId: peerId,
            peerName: args['peerName']?.toString() ?? 'Chat',
            peerPhone: args['peerPhone']?.toString(),
          ),
        );
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
