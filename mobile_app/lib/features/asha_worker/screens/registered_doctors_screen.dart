import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/signaling_service.dart';
import '../../../providers/auth_provider.dart';
import '../../user/services/doctor_service.dart';
import '../../user/screens/call_screen.dart';

class RegisteredDoctorsScreen extends StatefulWidget {
  const RegisteredDoctorsScreen({super.key});

  @override
  State<RegisteredDoctorsScreen> createState() => _RegisteredDoctorsScreenState();
}

class _RegisteredDoctorsScreenState extends State<RegisteredDoctorsScreen> {
  final ApiService _api = ApiService();
  final DoctorService _doctorService = DoctorService();
  List<dynamic> _doctors = [];
  bool _isLoading = true;

  final Color primaryBlue = const Color(0xFF2A7DE1);
  final Color textPrimary = const Color(0xFF1F2937);

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.get('/users/doctors/');
      setState(() {
        _doctors = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching doctors: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startCall(Map<String, dynamic> doctor, String type) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final consultation = await _doctorService.startConsultation(doctor['id'], type.toUpperCase());
      
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final signaling = SignalingService();
        
        signaling.sendCallRequest(
          receiverId: doctor['user_id']?.toString() ?? doctor['id'].toString(),
          consultationId: consultation['id'].toString(),
          callerName: authProvider.user?.name ?? 'ASHA Worker',
          callType: type.toUpperCase(),
        );

        Navigator.pop(context); // Remove loading indicator
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CallScreen(
              consultationId: consultation['id'].toString(),
              doctorName: doctor['full_name'] ?? doctor['name'] ?? 'Doctor',
              isVideo: type == 'video',
              isOfferer: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start call: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        title: Text(
          'Registered Doctors',
          style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDoctors,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _doctors.isEmpty
              ? const Center(child: Text('No doctors registered yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = _doctors[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.medical_services, color: primaryBlue, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doctor['full_name'] ?? doctor['name'] ?? 'Dr. Unknown',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      doctor['specialization'] ?? 'General Physician',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (doctor['is_available'] ?? true) ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  (doctor['is_available'] ?? true) ? 'Available' : 'Busy',
                                  style: TextStyle(
                                    color: (doctor['is_available'] ?? true) ? Colors.green : Colors.red,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _startCall(doctor, 'video'),
                                  icon: const Icon(Icons.videocam_outlined, size: 18),
                                  label: const Text('Video Call', style: TextStyle(fontSize: 13)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: primaryBlue,
                                    side: BorderSide(color: primaryBlue),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _startCall(doctor, 'audio'),
                                  icon: const Icon(Icons.phone_outlined, size: 18),
                                  label: const Text('Audio Call', style: TextStyle(fontSize: 13)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
