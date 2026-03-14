class AppConfig {
  // Replace this with your computer's local IP address (e.g., 192.168.1.5)
  // to test on physical devices connected to the same WiFi.
  // Use http://10.0.2.2:5000 for Android Emulator.
  static const String signalingServerUrl = 'http://172.16.8.10:5000';

  // Replace this with your computer's local IP address for Django backend.
  static const String baseUrl = 'http://172.16.8.10:8000/api';
}
