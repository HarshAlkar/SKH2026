class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
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
