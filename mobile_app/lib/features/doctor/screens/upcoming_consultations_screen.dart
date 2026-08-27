import 'package:flutter/material.dart';
import '../../../core/services/call_launcher.dart';
import '../services/doctor_appointment_service.dart';
import 'patient_details_screen.dart';
import 'dart:async';

class UpcomingConsultationsScreen extends StatefulWidget {
  const UpcomingConsultationsScreen({super.key});

  @override
  State<UpcomingConsultationsScreen> createState() => _UpcomingConsultationsScreenState();
}

class _UpcomingConsultationsScreenState extends State<UpcomingConsultationsScreen> {
  final DoctorAppointmentService _appointmentService = DoctorAppointmentService();
  final Color primaryBlue = const Color(0xFF2A7DE1);
  final Color lightBg = const Color(0xFFF3F4F6);
  final Color cardBg = const Color(0xFFFFFFFF);
  final Color videoColor = const Color(0xFF2563EB);
  final Color audioColor = const Color(0xFF10B981);
  final Color offlineColor = const Color(0xFFF59E0B);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);

  List<DoctorAppointment> _appointments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _appointmentService.getUpcomingAppointments();
      if (!mounted) return;
      setState(() {
        _appointments = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load upcoming consultations.';
        _isLoading = false;
      });
    }
  }

  int _calculateRemainingSeconds(DoctorAppointment appointment) {
    try {
      final now = DateTime.now();
      final dateStr = appointment.rawDate;
      final timeStr = appointment.rawTime;
      if (dateStr.isNotEmpty && timeStr.isNotEmpty) {
        final parsed = DateTime.parse('${dateStr}T$timeStr');
        final diff = parsed.difference(now).inSeconds;
        return diff > 0 ? diff : 0;
      }
    } catch (_) {}
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Upcoming Consultations',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: textPrimary, size: 20),
            onPressed: _loadAppointments,
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A7DE1)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: TextStyle(color: textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAppointments,
              style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.video_call_outlined, size: 56, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 16),
            Text(
              'No upcoming consultations scheduled.',
              style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Scheduled appointments will appear here.',
              style: TextStyle(color: textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _appointments.length,
        itemBuilder: (context, index) {
          return _buildConsultationCard(_appointments[index]);
        },
      ),
    );
  }

  Widget _buildConsultationCard(DoctorAppointment appointment) {
    bool isVideo = appointment.type == DoctorConsultationType.video;
    bool isAudio = appointment.type == DoctorConsultationType.audio;
    Color typeColor = isVideo ? videoColor : (isAudio ? audioColor : offlineColor);
    IconData typeIcon = isVideo ? Icons.videocam : (isAudio ? Icons.phone : Icons.local_hospital);
    String typeLabel = isVideo ? 'Video Consultation' : (isAudio ? 'Audio Consultation' : 'Offline Visit');

    final remainingSeconds = _calculateRemainingSeconds(appointment);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: typeColor.withOpacity(0.1),
                      child: Text(
                        appointment.patientName.isNotEmpty
                            ? appointment.patientName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('')
                            : 'P',
                        style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.patientName,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(typeIcon, size: 14, color: typeColor),
                              const SizedBox(width: 4),
                              Text(
                                typeLabel,
                                style: TextStyle(
                                  color: typeColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${appointment.rawDate} · ${appointment.formattedTime}',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (remainingSeconds > 0)
                      _CountdownBadge(initialSeconds: remainingSeconds)
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8FDF0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Ready',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PatientDetailsScreen(patient: appointment.toPatientData()),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'View Details',
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (appointment.type == DoctorConsultationType.offline) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PatientDetailsScreen(patient: appointment.toPatientData()),
                              ),
                            );
                          } else {
                            final targetUserId = appointment.patientUserId?.toString() ?? appointment.patientId.toString();
                            CallLauncher.start(
                              context: context,
                              peerName: appointment.patientName,
                              receiverUserId: targetUserId,
                              isVideo: appointment.type == DoctorConsultationType.video,
                              doctorId: appointment.doctorId,
                              patientId: appointment.patientId,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: typeColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          appointment.type == DoctorConsultationType.offline
                              ? 'Offline Details'
                              : (isVideo ? 'Start Video Call' : 'Start Audio Call'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownBadge extends StatefulWidget {
  final int initialSeconds;
  const _CountdownBadge({required this.initialSeconds});

  @override
  State<_CountdownBadge> createState() => _CountdownBadgeState();
}

class _CountdownBadgeState extends State<_CountdownBadge> {
  late int _seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _seconds = widget.initialSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        if (mounted) {
          setState(() {
            _seconds--;
          });
        }
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Starts in ${_formatDuration(_seconds)}',
        style: const TextStyle(
          color: Color(0xFFD97706),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
