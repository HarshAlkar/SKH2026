import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'VitalReach'**
  String get appName;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutAccount.
  ///
  /// In en, this message translates to:
  /// **'Logout Account'**
  String get logoutAccount;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'DISMISS'**
  String get dismiss;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get viewProfile;

  /// No description provided for @yourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get yourProfile;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get hindi;

  /// No description provided for @marathi.
  ///
  /// In en, this message translates to:
  /// **'मराठी'**
  String get marathi;

  /// No description provided for @villageLabel.
  ///
  /// In en, this message translates to:
  /// **'Village: {village}'**
  String villageLabel(String village);

  /// No description provided for @helloUser.
  ///
  /// In en, this message translates to:
  /// **'Hello {name}'**
  String helloUser(String name);

  /// No description provided for @howFeelingToday.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling today?'**
  String get howFeelingToday;

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Select your role to continue'**
  String get selectRole;

  /// No description provided for @serverCloudOrPc.
  ///
  /// In en, this message translates to:
  /// **'Server (cloud or PC)'**
  String get serverCloudOrPc;

  /// No description provided for @activeApi.
  ///
  /// In en, this message translates to:
  /// **'Active API: {url}'**
  String activeApi(String url);

  /// No description provided for @callsAuto.
  ///
  /// In en, this message translates to:
  /// **'Calls auto: {url}'**
  String callsAuto(String url);

  /// No description provided for @serverHint.
  ///
  /// In en, this message translates to:
  /// **'Cloud: https://your-api.onrender.com  ·  Emulator: 10.0.2.2  ·  Phone: PC Wi-Fi IP'**
  String get serverHint;

  /// No description provided for @saveHost.
  ///
  /// In en, this message translates to:
  /// **'Save host'**
  String get saveHost;

  /// No description provided for @rolePatient.
  ///
  /// In en, this message translates to:
  /// **'Villager / Patient'**
  String get rolePatient;

  /// No description provided for @rolePatientDesc.
  ///
  /// In en, this message translates to:
  /// **'Check symptoms, track medicines, and consult doctors for your family\'s health.'**
  String get rolePatientDesc;

  /// No description provided for @continueAsPatient.
  ///
  /// In en, this message translates to:
  /// **'Continue as Patient'**
  String get continueAsPatient;

  /// No description provided for @roleAsha.
  ///
  /// In en, this message translates to:
  /// **'ASHA Worker'**
  String get roleAsha;

  /// No description provided for @roleAshaDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage village health data, track community visits, and assist local patients.'**
  String get roleAshaDesc;

  /// No description provided for @continueAsAsha.
  ///
  /// In en, this message translates to:
  /// **'Continue as ASHA'**
  String get continueAsAsha;

  /// No description provided for @roleDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get roleDoctor;

  /// No description provided for @roleDoctorDesc.
  ///
  /// In en, this message translates to:
  /// **'Provide telemedicine consultation and expert medical advice to rural communities.'**
  String get roleDoctorDesc;

  /// No description provided for @continueAsDoctor.
  ///
  /// In en, this message translates to:
  /// **'Continue as Doctor'**
  String get continueAsDoctor;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'© 2026 VitalReach.\nHealthcare reaching everywhere.'**
  String get copyright;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @enterPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 10-digit mobile number'**
  String get enterPhoneHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPasswordHint;

  /// No description provided for @forgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot?'**
  String get forgot;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @loginWithOtp.
  ///
  /// In en, this message translates to:
  /// **'Login with OTP'**
  String get loginWithOtp;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please check your credentials.'**
  String get loginFailed;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 10-digit phone number'**
  String get invalidPhone;

  /// No description provided for @otpSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send OTP. Is your phone number registered?'**
  String get otpSendFailed;

  /// No description provided for @newUser.
  ///
  /// In en, this message translates to:
  /// **'New user? '**
  String get newUser;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @registrationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Registration Successful!'**
  String get registrationSuccessful;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registrationFailed;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @village.
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get village;

  /// No description provided for @patient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patient;

  /// No description provided for @doctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctor;

  /// No description provided for @ashaWorker.
  ///
  /// In en, this message translates to:
  /// **'ASHA Worker'**
  String get ashaWorker;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get account;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get notifications;

  /// No description provided for @languageSection.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get languageSection;

  /// No description provided for @serverSection.
  ///
  /// In en, this message translates to:
  /// **'SERVER'**
  String get serverSection;

  /// No description provided for @offlineEmergency.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE EMERGENCY'**
  String get offlineEmergency;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get about;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @newPasswordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'New passwords do not match'**
  String get newPasswordsMismatch;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get passwordUpdated;

  /// No description provided for @passwordChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not change password'**
  String get passwordChangeFailed;

  /// No description provided for @incomingCalls.
  ///
  /// In en, this message translates to:
  /// **'Incoming calls'**
  String get incomingCalls;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @medicineReminders.
  ///
  /// In en, this message translates to:
  /// **'Medicine reminders'**
  String get medicineReminders;

  /// No description provided for @apiHost.
  ///
  /// In en, this message translates to:
  /// **'API host'**
  String get apiHost;

  /// No description provided for @serverHostSaved.
  ///
  /// In en, this message translates to:
  /// **'Server host saved. API: {url}'**
  String serverHostSaved(String url);

  /// No description provided for @esp32GatewaySaved.
  ///
  /// In en, this message translates to:
  /// **'ESP32 gateway saved: {value}'**
  String esp32GatewaySaved(String value);

  /// No description provided for @mockSimulation.
  ///
  /// In en, this message translates to:
  /// **'Mock / simulation'**
  String get mockSimulation;

  /// No description provided for @mockSimulationSub.
  ///
  /// In en, this message translates to:
  /// **'No radio. Logs packet hops.'**
  String get mockSimulationSub;

  /// No description provided for @localEsp32Wifi.
  ///
  /// In en, this message translates to:
  /// **'Local ESP32 Wi-Fi'**
  String get localEsp32Wifi;

  /// No description provided for @localEsp32WifiSub.
  ///
  /// In en, this message translates to:
  /// **'HTTP to gateway AP. Radio optional.'**
  String get localEsp32WifiSub;

  /// No description provided for @loraViaEsp32.
  ///
  /// In en, this message translates to:
  /// **'LoRa via ESP32'**
  String get loraViaEsp32;

  /// No description provided for @loraViaEsp32Sub.
  ///
  /// In en, this message translates to:
  /// **'Same HTTP; firmware TX on radio when wired.'**
  String get loraViaEsp32Sub;

  /// No description provided for @esp32Gateway.
  ///
  /// In en, this message translates to:
  /// **'ESP32 gateway'**
  String get esp32Gateway;

  /// No description provided for @saveGateway.
  ///
  /// In en, this message translates to:
  /// **'Save gateway'**
  String get saveGateway;

  /// No description provided for @injecting.
  ///
  /// In en, this message translates to:
  /// **'Injecting...'**
  String get injecting;

  /// No description provided for @simulateIncomingLora.
  ///
  /// In en, this message translates to:
  /// **'Simulate incoming LoRa packet'**
  String get simulateIncomingLora;

  /// No description provided for @simulatedPacketInjected.
  ///
  /// In en, this message translates to:
  /// **'Simulated emergency packet injected'**
  String get simulatedPacketInjected;

  /// No description provided for @couldNotSimulatePacket.
  ///
  /// In en, this message translates to:
  /// **'Could not simulate packet'**
  String get couldNotSimulatePacket;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersion;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @todaysHealthTips.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Health Tips'**
  String get todaysHealthTips;

  /// No description provided for @aiSymptomChecker.
  ///
  /// In en, this message translates to:
  /// **'AI Symptom Checker'**
  String get aiSymptomChecker;

  /// No description provided for @aiSymptomCheckerTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Symptom\nChecker'**
  String get aiSymptomCheckerTitle;

  /// No description provided for @checkSymptomsGuidance.
  ///
  /// In en, this message translates to:
  /// **'Check your symptoms and get\ninstant guidance.'**
  String get checkSymptomsGuidance;

  /// No description provided for @checkSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Check Symptoms'**
  String get checkSymptoms;

  /// No description provided for @verifyInfo.
  ///
  /// In en, this message translates to:
  /// **'Verify Info'**
  String get verifyInfo;

  /// No description provided for @oneHealth.
  ///
  /// In en, this message translates to:
  /// **'One Health'**
  String get oneHealth;

  /// No description provided for @medicineTracker.
  ///
  /// In en, this message translates to:
  /// **'Medicine Tracker'**
  String get medicineTracker;

  /// No description provided for @nearbyClinics.
  ///
  /// In en, this message translates to:
  /// **'Nearby Clinics'**
  String get nearbyClinics;

  /// No description provided for @bookAppointment.
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get bookAppointment;

  /// No description provided for @myAppointments.
  ///
  /// In en, this message translates to:
  /// **'My Appointments'**
  String get myAppointments;

  /// No description provided for @ashaWorkers.
  ///
  /// In en, this message translates to:
  /// **'ASHA Workers'**
  String get ashaWorkers;

  /// No description provided for @myPrescriptions.
  ///
  /// In en, this message translates to:
  /// **'My Prescriptions'**
  String get myPrescriptions;

  /// No description provided for @healthTips.
  ///
  /// In en, this message translates to:
  /// **'Health Tips'**
  String get healthTips;

  /// No description provided for @childCheck.
  ///
  /// In en, this message translates to:
  /// **'Child check'**
  String get childCheck;

  /// No description provided for @livestock.
  ///
  /// In en, this message translates to:
  /// **'Livestock'**
  String get livestock;

  /// No description provided for @medicineAvailability.
  ///
  /// In en, this message translates to:
  /// **'Medicine Availability'**
  String get medicineAvailability;

  /// No description provided for @consultDoctor.
  ///
  /// In en, this message translates to:
  /// **'Consult Doctor'**
  String get consultDoctor;

  /// No description provided for @callHistory.
  ///
  /// In en, this message translates to:
  /// **'Call History'**
  String get callHistory;

  /// No description provided for @emergencyHelp.
  ///
  /// In en, this message translates to:
  /// **'Emergency Help'**
  String get emergencyHelp;

  /// No description provided for @immediateSupport.
  ///
  /// In en, this message translates to:
  /// **'Immediate medical support'**
  String get immediateSupport;

  /// No description provided for @callEmergency.
  ///
  /// In en, this message translates to:
  /// **'Call Emergency'**
  String get callEmergency;

  /// No description provided for @ashaInVillage.
  ///
  /// In en, this message translates to:
  /// **'ASHA workers in your village'**
  String get ashaInVillage;

  /// No description provided for @paracetamolReminder.
  ///
  /// In en, this message translates to:
  /// **'Paracetamol reminder'**
  String get paracetamolReminder;

  /// No description provided for @scheduledAt8pm.
  ///
  /// In en, this message translates to:
  /// **'Scheduled at 8:00 PM'**
  String get scheduledAt8pm;

  /// No description provided for @stayHydrated.
  ///
  /// In en, this message translates to:
  /// **'Stay Hydrated'**
  String get stayHydrated;

  /// No description provided for @stayHydratedDesc.
  ///
  /// In en, this message translates to:
  /// **'Drink at least 8 glasses of\nwater daily.'**
  String get stayHydratedDesc;

  /// No description provided for @morningWalk.
  ///
  /// In en, this message translates to:
  /// **'Morning Walk'**
  String get morningWalk;

  /// No description provided for @morningWalkDesc.
  ///
  /// In en, this message translates to:
  /// **'A 15-minute walk boosts\nyour energy.'**
  String get morningWalkDesc;

  /// No description provided for @sleepWell.
  ///
  /// In en, this message translates to:
  /// **'Sleep Well'**
  String get sleepWell;

  /// No description provided for @sleepWellDesc.
  ///
  /// In en, this message translates to:
  /// **'Get 7-8 hours of quality sleep\nevery night.'**
  String get sleepWellDesc;

  /// No description provided for @villagePatients.
  ///
  /// In en, this message translates to:
  /// **'Village Patients'**
  String get villagePatients;

  /// No description provided for @callChat.
  ///
  /// In en, this message translates to:
  /// **'Call / Chat'**
  String get callChat;

  /// No description provided for @riskAlerts.
  ///
  /// In en, this message translates to:
  /// **'Risk Alerts'**
  String get riskAlerts;

  /// No description provided for @healthReports.
  ///
  /// In en, this message translates to:
  /// **'Health Reports'**
  String get healthReports;

  /// No description provided for @registerPatient.
  ///
  /// In en, this message translates to:
  /// **'Register Patient'**
  String get registerPatient;

  /// No description provided for @villageVisits.
  ///
  /// In en, this message translates to:
  /// **'Village Visits'**
  String get villageVisits;

  /// No description provided for @updateStock.
  ///
  /// In en, this message translates to:
  /// **'Update Stock'**
  String get updateStock;

  /// No description provided for @healthRecords.
  ///
  /// In en, this message translates to:
  /// **'Health Records'**
  String get healthRecords;

  /// No description provided for @emergencyReferral.
  ///
  /// In en, this message translates to:
  /// **'Emergency Referral'**
  String get emergencyReferral;

  /// No description provided for @referralHistory.
  ///
  /// In en, this message translates to:
  /// **'Referral History'**
  String get referralHistory;

  /// No description provided for @assignedVillage.
  ///
  /// In en, this message translates to:
  /// **'Assigned Village'**
  String get assignedVillage;

  /// No description provided for @doctorDashboard.
  ///
  /// In en, this message translates to:
  /// **'Doctor Dashboard'**
  String get doctorDashboard;

  /// No description provided for @performanceSummary.
  ///
  /// In en, this message translates to:
  /// **'PERFORMANCE SUMMARY'**
  String get performanceSummary;

  /// No description provided for @quickActionsCaps.
  ///
  /// In en, this message translates to:
  /// **'QUICK ACTIONS'**
  String get quickActionsCaps;

  /// No description provided for @mainMenu.
  ///
  /// In en, this message translates to:
  /// **'MAIN MENU'**
  String get mainMenu;

  /// No description provided for @insightsSettings.
  ///
  /// In en, this message translates to:
  /// **'INSIGHTS & SETTINGS'**
  String get insightsSettings;

  /// No description provided for @patientRequests.
  ///
  /// In en, this message translates to:
  /// **'Patient Requests'**
  String get patientRequests;

  /// No description provided for @myPatients.
  ///
  /// In en, this message translates to:
  /// **'My Patients'**
  String get myPatients;

  /// No description provided for @medicineStock.
  ///
  /// In en, this message translates to:
  /// **'Medicine Stock'**
  String get medicineStock;

  /// No description provided for @consultations.
  ///
  /// In en, this message translates to:
  /// **'Consultations'**
  String get consultations;

  /// No description provided for @prescriptions.
  ///
  /// In en, this message translates to:
  /// **'Prescriptions'**
  String get prescriptions;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @couldNotLoadData.
  ///
  /// In en, this message translates to:
  /// **'Could not load data from {host}. Log out and log in again.'**
  String couldNotLoadData(String host);

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @symptomHowFeel.
  ///
  /// In en, this message translates to:
  /// **'How do you feel?'**
  String get symptomHowFeel;

  /// No description provided for @symptomDesc.
  ///
  /// In en, this message translates to:
  /// **'Our AI helps identify potential health concerns'**
  String get symptomDesc;

  /// No description provided for @commonSymptoms.
  ///
  /// In en, this message translates to:
  /// **'COMMON SYMPTOMS'**
  String get commonSymptoms;

  /// No description provided for @voiceDesc.
  ///
  /// In en, this message translates to:
  /// **'Or describe symptoms by voice'**
  String get voiceDesc;

  /// No description provided for @tapVoice.
  ///
  /// In en, this message translates to:
  /// **'Tap for Voice Input'**
  String get tapVoice;

  /// No description provided for @listeningSpeak.
  ///
  /// In en, this message translates to:
  /// **'Listening... Please speak now'**
  String get listeningSpeak;

  /// No description provided for @analyzeSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Analyze Symptoms'**
  String get analyzeSymptoms;

  /// No description provided for @analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get analyzing;

  /// No description provided for @tabSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get tabSymptoms;

  /// No description provided for @tabSkin.
  ///
  /// In en, this message translates to:
  /// **'Skin photo'**
  String get tabSkin;

  /// No description provided for @skinDesc.
  ///
  /// In en, this message translates to:
  /// **'Take or choose a clear photo of the affected skin'**
  String get skinDesc;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @pickGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get pickGallery;

  /// No description provided for @analyzeSkin.
  ///
  /// In en, this message translates to:
  /// **'Analyze Skin'**
  String get analyzeSkin;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @usePhoto.
  ///
  /// In en, this message translates to:
  /// **'Use Photo'**
  String get usePhoto;

  /// No description provided for @cameraDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission was denied. You can still choose a photo from Gallery.'**
  String get cameraDenied;

  /// No description provided for @skinSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Or select skin symptoms from dataset'**
  String get skinSymptoms;

  /// No description provided for @skinDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'AI-assisted skin screening only. Screening confidence is not a confirmed diagnosis. Professional evaluation recommended.'**
  String get skinDisclaimer;

  /// No description provided for @resultTitleSkin.
  ///
  /// In en, this message translates to:
  /// **'AI SKIN SCREENING'**
  String get resultTitleSkin;

  /// No description provided for @askAi.
  ///
  /// In en, this message translates to:
  /// **'Ask AI about this'**
  String get askAi;

  /// No description provided for @contactDoctor.
  ///
  /// In en, this message translates to:
  /// **'Contact Doctor'**
  String get contactDoctor;

  /// No description provided for @contactAsha.
  ///
  /// In en, this message translates to:
  /// **'Contact ASHA'**
  String get contactAsha;

  /// No description provided for @ashaNotified.
  ///
  /// In en, this message translates to:
  /// **'ASHA notified'**
  String get ashaNotified;

  /// No description provided for @screeningDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'AI-assisted screening only. This is not a medical or veterinary diagnosis.'**
  String get screeningDisclaimer;

  /// No description provided for @possibleCondition.
  ///
  /// In en, this message translates to:
  /// **'Possible condition (screening)'**
  String get possibleCondition;

  /// No description provided for @aiConfidence.
  ///
  /// In en, this message translates to:
  /// **'AI confidence'**
  String get aiConfidence;

  /// No description provided for @selectFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one symptom or describe what you are experiencing.'**
  String get selectFirst;

  /// No description provided for @describeTitle.
  ///
  /// In en, this message translates to:
  /// **'Describe your symptoms'**
  String get describeTitle;

  /// No description provided for @describeHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Fever for 3 days, headache and vomiting'**
  String get describeHint;

  /// No description provided for @symptomsDetected.
  ///
  /// In en, this message translates to:
  /// **'Symptoms detected'**
  String get symptomsDetected;

  /// No description provided for @voiceNote.
  ///
  /// In en, this message translates to:
  /// **'Voice transcription may require connectivity. Typed text works offline.'**
  String get voiceNote;

  /// No description provided for @insufficient.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t confidently identify enough symptoms from your description.'**
  String get insufficient;

  /// No description provided for @insufficientHint.
  ///
  /// In en, this message translates to:
  /// **'Please add more details or select symptoms from the list.'**
  String get insufficientHint;

  /// No description provided for @aiSource.
  ///
  /// In en, this message translates to:
  /// **'AI source'**
  String get aiSource;

  /// No description provided for @analysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Analysis failed'**
  String get analysisFailed;

  /// No description provided for @speechDenied.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition not available or permission denied'**
  String get speechDenied;

  /// No description provided for @skinFirst.
  ///
  /// In en, this message translates to:
  /// **'Take a skin photo or select skin symptoms'**
  String get skinFirst;

  /// No description provided for @severityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get severityLow;

  /// No description provided for @severityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get severityModerate;

  /// No description provided for @severityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get severityHigh;

  /// No description provided for @severityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get severityCritical;

  /// No description provided for @speechUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition not available'**
  String get speechUnavailable;

  /// No description provided for @askAiAboutResult.
  ///
  /// In en, this message translates to:
  /// **'Ask anything about this {domain} result — what it means, what to watch for, home care, or next steps.\nAnswers come from Gemini with an Evidence section.\n\n{disclaimer}'**
  String askAiAboutResult(String domain, String disclaimer);

  /// No description provided for @aiChatRequiresInternet.
  ///
  /// In en, this message translates to:
  /// **'AI chat requires an internet connection, but your screening result and recommended next steps are available offline.'**
  String get aiChatRequiresInternet;

  /// No description provided for @aiChatNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'AI chat is not configured on the server. Set GEMINI_API_KEY in Django (.env / Render). Screening results remain available offline without Gemini.'**
  String get aiChatNotConfigured;

  /// No description provided for @typeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Type your question'**
  String get typeQuestion;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @aiHealthChat.
  ///
  /// In en, this message translates to:
  /// **'AI Health Chat'**
  String get aiHealthChat;

  /// No description provided for @verifyHealthInfo.
  ///
  /// In en, this message translates to:
  /// **'Verify Health Information'**
  String get verifyHealthInfo;

  /// No description provided for @pasteClaimHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a WhatsApp forward or health claim'**
  String get pasteClaimHint;

  /// No description provided for @checkClaim.
  ///
  /// In en, this message translates to:
  /// **'Check claim'**
  String get checkClaim;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checking;

  /// No description provided for @tryDemo.
  ///
  /// In en, this message translates to:
  /// **'Try a demo claim'**
  String get tryDemo;

  /// No description provided for @shareGuidance.
  ///
  /// In en, this message translates to:
  /// **'Share guidance'**
  String get shareGuidance;

  /// No description provided for @reportMisinfo.
  ///
  /// In en, this message translates to:
  /// **'Report misinformation'**
  String get reportMisinfo;

  /// No description provided for @oneHealthHub.
  ///
  /// In en, this message translates to:
  /// **'One Health'**
  String get oneHealthHub;

  /// No description provided for @humanScreening.
  ///
  /// In en, this message translates to:
  /// **'Human screening'**
  String get humanScreening;

  /// No description provided for @livestockScreening.
  ///
  /// In en, this message translates to:
  /// **'Livestock screening'**
  String get livestockScreening;

  /// No description provided for @childDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Child development'**
  String get childDevelopment;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get saveProfile;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @bloodGroup.
  ///
  /// In en, this message translates to:
  /// **'Blood group'**
  String get bloodGroup;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @medicalHistory.
  ///
  /// In en, this message translates to:
  /// **'Medical history'**
  String get medicalHistory;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
