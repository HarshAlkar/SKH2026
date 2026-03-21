import 'package:flutter/material.dart';
import '../core/services/realtime_service.dart';
import '../models/prescription_model.dart';
import '../core/keys/navigator_key.dart';

class RealtimeProvider with ChangeNotifier {
  final RealtimeService _realtime = RealtimeService();
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  void initialize(String userId) {
    if (_isConnected) return;
    
    _realtime.connect(userId);
    _isConnected = true;

    _realtime.onNewPrescription = (prescription) {
      _showPrescriptionAlert(prescription);
      notifyListeners();
    };

    _realtime.onNotification = (title, body) {
      _showSystemAlert(title, body);
      notifyListeners();
    };
  }

  void _showPrescriptionAlert(PrescriptionModel prescription) {
    if (navigatorKey.currentContext != null) {
      showDialog(
        context: navigatorKey.currentContext!,
        builder: (ctx) => AlertDialog(
          title: const Text('New Prescription Received!'),
          content: Text('Dr. ${prescription.doctorName} has issued a new prescription for you.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void sendPrescription(String receiverId, Map<String, dynamic> prescription) {
    _realtime.sendPrescription(receiverId, prescription);
  }

  void _showSystemAlert(String title, String body) {
     if (navigatorKey.currentContext != null) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(body),
            ],
          ),
          backgroundColor: Colors.blueAccent,
        )
      );
    }
  }

  @override
  void dispose() {
    _realtime.disconnect();
    super.dispose();
  }
}
