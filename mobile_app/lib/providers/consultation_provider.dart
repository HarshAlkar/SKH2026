import 'package:flutter/material.dart';
import '../features/user/services/doctor_service.dart';
import '../core/services/signaling_service.dart';
import '../features/user/screens/call_screen.dart';
import '../main.dart';

class ConsultationProvider extends ChangeNotifier {
  final DoctorService _doctorService = DoctorService();
  final SignalingService _signaling = SignalingService();
  
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get history => _history;
  bool get isLoading => _isLoading;

  void initSignaling(String userId) {
    _signaling.connect(userId);
    
    // Listen for incoming call requests
    _signaling.onIncomingCall((data) {
      _handleIncomingCall(data);
    });
  }

  void _handleIncomingCall(Map<String, dynamic> data) {
    final consultationId = data['consultationId'].toString();
    final callerName = data['callerName'] ?? 'Patient';
    final callType = data['callType'] ?? 'VIDEO';
    
    // Show incoming call dialog
    final context = navigatorKey.currentContext;
    if (context != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Incoming $callType Call'),
          content: Text('$callerName is requesting a consultation.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Reject', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CallScreen(
                      consultationId: consultationId,
                      doctorName: callerName,
                      isVideo: callType == 'VIDEO',
                      isOfferer: false,
                    ),
                  ),
                );
              },
              child: const Text('Accept'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> fetchHistory() async {
    _isLoading = true;
    notifyListeners();
    try {
      _history = await _doctorService.getConsultationHistory();
    } catch (e) {
      print('Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _signaling.dispose();
    super.dispose();
  }
}
