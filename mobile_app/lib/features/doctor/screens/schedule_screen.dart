import 'package:flutter/material.dart';
import 'video_consultation_screen.dart';
import 'audio_consultation_screen.dart';
import 'patient_details_screen.dart';
import '../../user/services/doctor_service.dart' as user_service;
import 'package:intl/intl.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final user_service.DoctorService _doctorService = user_service.DoctorService();
  List<dynamic> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    try {
      final appointments = await _doctorService.getTodayAppointments();
      if (mounted) {
        setState(() {
          _appointments = appointments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  final textPrimary = const Color(0xFF1F2937);
  final backgroundColor = const Color(0xFFF3F4F6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Today\'s Schedule',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, color: Color(0xFF1F2937)),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchAppointments,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateHeader(),
                  if (_appointments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(child: Text('No appointments scheduled for today.')),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _appointments.length,
                      itemBuilder: (context, index) {
                        return _buildAppointmentCard(context, _appointments[index]);
                      },
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDateHeader() {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE · MMM d, yyyy');
    
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatter.format(now),
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Today\'s Appointments',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Map<String, dynamic> appt) {
    const textPrimary = Color(0xFF1F2937);
    const textSecondary = Color(0xFF6B7280);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appt['time'] ?? '',
                  style: const TextStyle(
                    color: Color(0xFF2A7DE1),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFFF1F5F9),
                      child: Icon(Icons.person, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appt['patient_name'] ?? 'Unknown Patient',
                            style: const TextStyle(
                              color: textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Age: ${appt['age']} · Village: ${appt['village']}',
                            style: const TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildTypeBadge(appt['type']),
                  ],
                ),
                const SizedBox(height: 16),
                _buildHistorySection(appt),
                const SizedBox(height: 16),
                _buildActionButtons(context, appt),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String? type) {
    Color color;
    IconData icon;
    String label;

    if (type == 'VIDEO') {
      color = const Color(0xFF2563EB);
      icon = Icons.videocam;
      label = 'Video Call';
    } else if (type == 'AUDIO') {
      color = const Color(0xFF10B981);
      icon = Icons.phone;
      label = 'Audio Call';
    } else {
      color = const Color(0xFFF59E0B);
      icon = Icons.local_hospital;
      label = 'Offline Visit';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(Map<String, dynamic> appt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              const Text(
                'PREVIOUS HEALTH HISTORY',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            appt['history_summary'] ?? 'No history reported',
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (appt['is_emergency'] == true) ...[
            const SizedBox(height: 6),
            const Text(
              'EMERGENCY CASE',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Map<String, dynamic> appt) {
    final type = appt['type'];
    if (type == 'VIDEO') {
      return SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoConsultationScreen(
                  consultationId: appt['id'].toString(),
                ),
              ),
            );
          },
          icon: const Icon(Icons.videocam, size: 18),
          label: const Text('Start Video Call', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2A7DE1),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    } else if (type == 'AUDIO') {
      return SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AudioConsultationScreen(),
              ),
            );
          },
          icon: const Icon(Icons.phone, size: 18),
          label: const Text('Start Audio Call', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        height: 44,
        child: OutlinedButton(
          onPressed: () {
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => PatientDetailsScreen(patient: appt['patient_id']), // This would need a real PatientData object
            //   ),
            // );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFF59E0B),
            side: const BorderSide(color: Color(0xFFF59E0B)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('View Appointment Details', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }
  }
}
