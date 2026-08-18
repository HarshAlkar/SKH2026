import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/call_launcher.dart';

class RegisteredDoctorsScreen extends StatefulWidget {
  final int? forPatientId;
  const RegisteredDoctorsScreen({super.key, this.forPatientId});

  @override
  State<RegisteredDoctorsScreen> createState() => _RegisteredDoctorsScreenState();
}

class _RegisteredDoctorsScreenState extends State<RegisteredDoctorsScreen> {
  final ApiService _api = ApiService();
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
      final data = await _api.get('/doctors/');
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
    final doctorId = int.tryParse(doctor['id'].toString());
    if (doctorId == null) return;
    await CallLauncher.start(
      context: context,
      peerName: doctor['full_name']?.toString() ?? doctor['name']?.toString() ?? 'Doctor',
      receiverUserId: doctor['user_id']?.toString() ?? doctor['id'].toString(),
      isVideo: type == 'video',
      doctorId: doctorId,
      patientId: widget.forPatientId,
    );
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
