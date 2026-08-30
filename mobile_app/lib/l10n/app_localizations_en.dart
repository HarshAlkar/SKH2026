// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'VitalReach';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get logout => 'Logout';

  @override
  String get logoutAccount => 'Logout Account';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get update => 'Update';

  @override
  String get ok => 'OK';

  @override
  String get retry => 'Retry';

  @override
  String get dismiss => 'DISMISS';

  @override
  String get loading => 'Loading...';

  @override
  String get saving => 'Saving...';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get guest => 'Guest';

  @override
  String get unknown => 'Unknown';

  @override
  String get viewProfile => 'View profile';

  @override
  String get yourProfile => 'Your profile';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get hindi => 'हिन्दी';

  @override
  String get marathi => 'मराठी';

  @override
  String villageLabel(String village) {
    return 'Village: $village';
  }

  @override
  String helloUser(String name) {
    return 'Hello $name';
  }

  @override
  String get howFeelingToday => 'How are you feeling today?';

  @override
  String get selectRole => 'Select your role to continue';

  @override
  String get serverCloudOrPc => 'Server (cloud or PC)';

  @override
  String activeApi(String url) {
    return 'Active API: $url';
  }

  @override
  String callsAuto(String url) {
    return 'Calls auto: $url';
  }

  @override
  String get serverHint =>
      'Cloud: https://your-api.onrender.com  ·  Emulator: 10.0.2.2  ·  Phone: PC Wi-Fi IP';

  @override
  String get saveHost => 'Save host';

  @override
  String get rolePatient => 'Villager / Patient';

  @override
  String get rolePatientDesc =>
      'Check symptoms, track medicines, and consult doctors for your family\'s health.';

  @override
  String get continueAsPatient => 'Continue as Patient';

  @override
  String get roleAsha => 'ASHA Worker';

  @override
  String get roleAshaDesc =>
      'Manage village health data, track community visits, and assist local patients.';

  @override
  String get continueAsAsha => 'Continue as ASHA';

  @override
  String get roleDoctor => 'Doctor';

  @override
  String get roleDoctorDesc =>
      'Provide telemedicine consultation and expert medical advice to rural communities.';

  @override
  String get continueAsDoctor => 'Continue as Doctor';

  @override
  String get copyright => '© 2026 VitalReach.\nHealthcare reaching everywhere.';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get enterPhoneHint => 'Enter 10-digit mobile number';

  @override
  String get password => 'Password';

  @override
  String get enterPasswordHint => 'Enter your password';

  @override
  String get forgot => 'Forgot?';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get loginWithOtp => 'Login with OTP';

  @override
  String get loginFailed => 'Login failed. Please check your credentials.';

  @override
  String get invalidPhone => 'Please enter a valid 10-digit phone number';

  @override
  String get otpSendFailed =>
      'Failed to send OTP. Is your phone number registered?';

  @override
  String get newUser => 'New user? ';

  @override
  String get createAccount => 'Create Account';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get registrationSuccessful => 'Registration Successful!';

  @override
  String get registrationFailed => 'Registration failed';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get fullName => 'Full name';

  @override
  String get email => 'Email';

  @override
  String get village => 'Village';

  @override
  String get patient => 'Patient';

  @override
  String get doctor => 'Doctor';

  @override
  String get ashaWorker => 'ASHA Worker';

  @override
  String get account => 'ACCOUNT';

  @override
  String get notifications => 'NOTIFICATIONS';

  @override
  String get languageSection => 'LANGUAGE';

  @override
  String get serverSection => 'SERVER';

  @override
  String get offlineEmergency => 'OFFLINE EMERGENCY';

  @override
  String get about => 'ABOUT';

  @override
  String get changePassword => 'Change password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get newPasswordsMismatch => 'New passwords do not match';

  @override
  String get passwordUpdated => 'Password updated';

  @override
  String get passwordChangeFailed => 'Could not change password';

  @override
  String get incomingCalls => 'Incoming calls';

  @override
  String get messages => 'Messages';

  @override
  String get medicineReminders => 'Medicine reminders';

  @override
  String get apiHost => 'API host';

  @override
  String serverHostSaved(String url) {
    return 'Server host saved. API: $url';
  }

  @override
  String esp32GatewaySaved(String value) {
    return 'ESP32 gateway saved: $value';
  }

  @override
  String get mockSimulation => 'Mock / simulation';

  @override
  String get mockSimulationSub => 'No radio. Logs packet hops.';

  @override
  String get localEsp32Wifi => 'Local ESP32 Wi-Fi';

  @override
  String get localEsp32WifiSub => 'HTTP to gateway AP. Radio optional.';

  @override
  String get loraViaEsp32 => 'LoRa via ESP32';

  @override
  String get loraViaEsp32Sub => 'Same HTTP; firmware TX on radio when wired.';

  @override
  String get esp32Gateway => 'ESP32 gateway';

  @override
  String get saveGateway => 'Save gateway';

  @override
  String get injecting => 'Injecting...';

  @override
  String get simulateIncomingLora => 'Simulate incoming LoRa packet';

  @override
  String get simulatedPacketInjected => 'Simulated emergency packet injected';

  @override
  String get couldNotSimulatePacket => 'Could not simulate packet';

  @override
  String get appVersion => 'App version';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get todaysHealthTips => 'Today\'s Health Tips';

  @override
  String get aiSymptomChecker => 'AI Symptom Checker';

  @override
  String get aiSymptomCheckerTitle => 'AI Symptom\nChecker';

  @override
  String get checkSymptomsGuidance =>
      'Check your symptoms and get\ninstant guidance.';

  @override
  String get checkSymptoms => 'Check Symptoms';

  @override
  String get verifyInfo => 'Verify Info';

  @override
  String get oneHealth => 'One Health';

  @override
  String get medicineTracker => 'Medicine Tracker';

  @override
  String get nearbyClinics => 'Nearby Clinics';

  @override
  String get bookAppointment => 'Book Appointment';

  @override
  String get myAppointments => 'My Appointments';

  @override
  String get ashaWorkers => 'ASHA Workers';

  @override
  String get myPrescriptions => 'My Prescriptions';

  @override
  String get healthTips => 'Health Tips';

  @override
  String get childCheck => 'Child check';

  @override
  String get livestock => 'Livestock';

  @override
  String get medicineAvailability => 'Medicine Availability';

  @override
  String get consultDoctor => 'Consult Doctor';

  @override
  String get callHistory => 'Call History';

  @override
  String get emergencyHelp => 'Emergency Help';

  @override
  String get immediateSupport => 'Immediate medical support';

  @override
  String get callEmergency => 'Call Emergency';

  @override
  String get ashaInVillage => 'ASHA workers in your village';

  @override
  String get paracetamolReminder => 'Paracetamol reminder';

  @override
  String get scheduledAt8pm => 'Scheduled at 8:00 PM';

  @override
  String get stayHydrated => 'Stay Hydrated';

  @override
  String get stayHydratedDesc => 'Drink at least 8 glasses of\nwater daily.';

  @override
  String get morningWalk => 'Morning Walk';

  @override
  String get morningWalkDesc => 'A 15-minute walk boosts\nyour energy.';

  @override
  String get sleepWell => 'Sleep Well';

  @override
  String get sleepWellDesc => 'Get 7-8 hours of quality sleep\nevery night.';

  @override
  String get villagePatients => 'Village Patients';

  @override
  String get callChat => 'Call / Chat';

  @override
  String get riskAlerts => 'Risk Alerts';

  @override
  String get healthReports => 'Health Reports';

  @override
  String get registerPatient => 'Register Patient';

  @override
  String get villageVisits => 'Village Visits';

  @override
  String get updateStock => 'Update Stock';

  @override
  String get healthRecords => 'Health Records';

  @override
  String get emergencyReferral => 'Emergency Referral';

  @override
  String get referralHistory => 'Referral History';

  @override
  String get assignedVillage => 'Assigned Village';

  @override
  String get doctorDashboard => 'Doctor Dashboard';

  @override
  String get performanceSummary => 'PERFORMANCE SUMMARY';

  @override
  String get quickActionsCaps => 'QUICK ACTIONS';

  @override
  String get mainMenu => 'MAIN MENU';

  @override
  String get insightsSettings => 'INSIGHTS & SETTINGS';

  @override
  String get patientRequests => 'Patient Requests';

  @override
  String get myPatients => 'My Patients';

  @override
  String get medicineStock => 'Medicine Stock';

  @override
  String get consultations => 'Consultations';

  @override
  String get prescriptions => 'Prescriptions';

  @override
  String get reports => 'Reports';

  @override
  String couldNotLoadData(String host) {
    return 'Could not load data from $host. Log out and log in again.';
  }

  @override
  String get home => 'Home';

  @override
  String get symptomHowFeel => 'How do you feel?';

  @override
  String get symptomDesc => 'Our AI helps identify potential health concerns';

  @override
  String get commonSymptoms => 'COMMON SYMPTOMS';

  @override
  String get voiceDesc => 'Or describe symptoms by voice';

  @override
  String get tapVoice => 'Tap for Voice Input';

  @override
  String get listeningSpeak => 'Listening... Please speak now';

  @override
  String get analyzeSymptoms => 'Analyze Symptoms';

  @override
  String get analyzing => 'Analyzing...';

  @override
  String get tabSymptoms => 'Symptoms';

  @override
  String get tabSkin => 'Skin photo';

  @override
  String get skinDesc =>
      'Select skin symptoms to screen for possible conditions';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get pickGallery => 'Choose from Gallery';

  @override
  String get analyzeSkin => 'Analyze Skin';

  @override
  String get retake => 'Retake';

  @override
  String get usePhoto => 'Use Photo';

  @override
  String get cameraDenied =>
      'Camera permission was denied. You can still choose a photo from Gallery.';

  @override
  String get skinSymptoms => 'Select skin symptoms';

  @override
  String get skinDisclaimer =>
      'AI-assisted skin screening only. Screening confidence is not a confirmed diagnosis. Professional evaluation recommended.';

  @override
  String get resultTitleSkin => 'AI SKIN SCREENING';

  @override
  String get askAi => 'Ask AI about this';

  @override
  String get contactDoctor => 'Contact Doctor';

  @override
  String get contactAsha => 'Contact ASHA';

  @override
  String get ashaNotified => 'ASHA notified';

  @override
  String get screeningDisclaimer =>
      'AI-assisted screening only. This is not a medical or veterinary diagnosis.';

  @override
  String get possibleCondition => 'Possible condition (screening)';

  @override
  String get aiConfidence => 'AI confidence';

  @override
  String get selectFirst =>
      'Please select at least one symptom or describe what you are experiencing.';

  @override
  String get describeTitle => 'Describe your symptoms';

  @override
  String get describeHint => 'Example: Fever for 3 days, headache and vomiting';

  @override
  String get symptomsDetected => 'Symptoms detected';

  @override
  String get voiceNote =>
      'Voice transcription may require connectivity. Typed text works offline.';

  @override
  String get insufficient =>
      'We couldn\'t confidently identify enough symptoms from your description.';

  @override
  String get insufficientHint =>
      'Please add more details or select symptoms from the list.';

  @override
  String get aiSource => 'AI source';

  @override
  String get analysisFailed => 'Analysis failed';

  @override
  String get speechDenied =>
      'Speech recognition not available or permission denied';

  @override
  String get skinFirst => 'Select at least one skin symptom';

  @override
  String get severityLow => 'Low';

  @override
  String get severityModerate => 'Moderate';

  @override
  String get severityHigh => 'High';

  @override
  String get severityCritical => 'Critical';

  @override
  String get speechUnavailable => 'Speech recognition not available';

  @override
  String askAiAboutResult(String domain, String disclaimer) {
    return 'Ask anything about this $domain result — what it means, what to watch for, home care, or next steps.\nAnswers come from Gemini with an Evidence section.\n\n$disclaimer';
  }

  @override
  String get aiChatRequiresInternet =>
      'AI chat requires an internet connection, but your screening result and recommended next steps are available offline.';

  @override
  String get aiChatNotConfigured =>
      'AI chat is not configured on the server. Set GEMINI_API_KEY in Django (.env / Render). Screening results remain available offline without Gemini.';

  @override
  String get typeQuestion => 'Type your question';

  @override
  String get send => 'Send';

  @override
  String get aiHealthChat => 'AI Health Chat';

  @override
  String get verifyHealthInfo => 'Verify Health Information';

  @override
  String get pasteClaimHint => 'Paste a WhatsApp forward or health claim';

  @override
  String get checkClaim => 'Check claim';

  @override
  String get checking => 'Checking...';

  @override
  String get tryDemo => 'Try a demo claim';

  @override
  String get shareGuidance => 'Share guidance';

  @override
  String get reportMisinfo => 'Report misinformation';

  @override
  String get oneHealthHub => 'One Health';

  @override
  String get humanScreening => 'Human screening';

  @override
  String get livestockScreening => 'Livestock screening';

  @override
  String get childDevelopment => 'Child development';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get saveProfile => 'Save profile';

  @override
  String get age => 'Age';

  @override
  String get gender => 'Gender';

  @override
  String get bloodGroup => 'Blood group';

  @override
  String get address => 'Address';

  @override
  String get medicalHistory => 'Medical history';
}
