import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    }
    
    // For mobile platforms, we check the target platform safely
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000/api';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return 'http://127.0.0.1:8000/api';
    }
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
}

