import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    }
    
    // For Android Emulator, always use 10.0.2.2
    return 'http://10.0.2.2:8000/api';
  }

  static const String loginEndpoint = '/auth/login/';
  static const String registerEndpoint = '/auth/register/';
  static const String logoutEndpoint = '/auth/logout/';
  static const String sendOtpEndpoint = '/auth/send-otp/';
  static const String verifyOtpEndpoint = '/auth/verify-otp/';
  static const String resetPasswordEndpoint = '/auth/reset-password/';
  static const String patientsEndpoint = '/patients/';
  static const String symptomsEndpoint = '/symptoms/';
  static const String consultationsEndpoint = '/consultations/';
  static const String prescriptionsEndpoint = '/prescriptions/';
  static const String alertsEndpoint = '/alerts/';
<<<<<<< HEAD
  static const String voiceSignalingUrl = AppConfig.signalingServerUrl;
=======
  static const String recordsEndpoint = '/records/';
  static const String ashaDashboardEndpoint = '/asha-workers/dashboard/';
>>>>>>> fee035fdefda48dc95a9fb53f469dc6dcaed41aa
}

