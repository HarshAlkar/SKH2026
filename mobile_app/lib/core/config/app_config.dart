class AppConfig {
  // Replace this with your computer's local IP address (e.g., 192.168.1.5)
  // to test on physical devices connected to the same WiFi.
  // Use http://10.0.2.2:5000 for Android Emulator.
<<<<<<< HEAD
  static const String signalingServerUrl = 'http://10.111.60.198:5000';

  // Replace this with your computer's local IP address for Django backend.
  static const String baseUrl = 'http://10.111.60.198:8000/api';
=======
  // Use http://127.0.0.1:5000 for iOS Simulator.
  static const String signalingServerUrl = 'http://127.0.0.1:5000';

  // Replace this with your computer's local IP address for Django backend.
  static const String baseUrl = 'http://127.0.0.1:8000/api';
>>>>>>> a29c117 (Prescription and Consultatncy)
}
