import 'package:flutter/material.dart';
import '../features/user/services/doctor_service.dart';
import '../core/services/signaling_service.dart';
import '../features/user/screens/call_screen.dart';
import '../features/doctor/screens/video_consultation_screen.dart';
import '../main.dart';

class ConsultationProvider extends ChangeNotifier {
  final DoctorService _doctorService = DoctorService();
  final SignalingService _signaling = SignalingService();
  
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _upcomingConsultations = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get history => _history;
  List<Map<String, dynamic>> get upcomingConsultations => _upcomingConsultations;
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
                    builder: (context) => VideoConsultationScreen(
                      consultationId: consultationId,
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

  void startConsultation({
    required String consultationId,
    required String patientId,
    required String patientName,
    required String doctorName,
    required bool isVideo,
  }) {
    _signaling.sendCallRequest(
      receiverId: patientId,
      consultationId: consultationId,
      callerName: doctorName,
      callType: isVideo ? 'VIDEO' : 'AUDIO',
    );
    
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoConsultationScreen(
            consultationId: consultationId,
          ),
        ),
      );
    }
  }

  Future<void> endConsultation(String consultationId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _doctorService.endConsultation(consultationId);
      await fetchUpcomingConsultations();
      await fetchHistory();
    } catch (e) {
      print('Error ending consultation: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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

  Future<void> fetchUpcomingConsultations() async {
    _isLoading = true;
    notifyListeners();
    try {
      _upcomingConsultations = await _doctorService.getPendingConsultations();
    } catch (e) {
      print('Error fetching upcoming consultations: $e');
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
