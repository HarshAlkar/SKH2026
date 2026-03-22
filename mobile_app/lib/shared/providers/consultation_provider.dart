import 'package:flutter/material.dart';
import 'package:hs053/features/user/services/doctor_service.dart';
import 'package:hs053/core/services/signaling_service.dart';
import 'package:hs053/features/user/screens/incoming_call_screen.dart';
import 'package:hs053/main.dart';

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
    final callerName = data['callerName'] ?? 'Doctor';
    final callType = data['callType'] ?? 'VIDEO';
    
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IncomingCallScreen(
            consultationId: consultationId,
            callerName: callerName,
            callType: callType,
          ),
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
      debugPrint('Error: $e');
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
