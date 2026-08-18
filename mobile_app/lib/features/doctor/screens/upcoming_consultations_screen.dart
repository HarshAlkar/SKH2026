import 'package:flutter/material.dart';
import 'patient_details_screen.dart';
import 'my_patients_screen.dart';
import 'dart:async';

class Consultation {
  final String patientName;
  final String type;
  final String time;
  final int initialSeconds;

  Consultation({
    required this.patientName,
    required this.type,
    required this.time,
    required this.initialSeconds,
  });
}

class UpcomingConsultationsScreen extends StatefulWidget {
  const UpcomingConsultationsScreen({super.key});

  @override
  State<UpcomingConsultationsScreen> createState() => _UpcomingConsultationsScreenState();
}

class _UpcomingConsultationsScreenState extends State<UpcomingConsultationsScreen> {
  final Color primaryBlue = const Color(0xFF2A7DE1);
  final Color lightBg = const Color(0xFFF3F4F6);
  final Color cardBg = const Color(0xFFFFFFFF);
  final Color videoColor = const Color(0xFF2563EB);
  final Color audioColor = const Color(0xFF10B981);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);

  final List<Consultation> _consultations = [
    Consultation(
      patientName: 'Sarah Jenkins',
      type: 'Video Consultation',
      time: 'Today · 10:30 AM',
      initialSeconds: 522, // 08:42
    ),
    Consultation(
      patientName: 'Ramesh Patil',
      type: 'Audio Consultation',
      time: 'Today · 11:00 AM',
      initialSeconds: 1090, // 18:10
    ),
    Consultation(
      patientName: 'Sunita Deshmukh',
      type: 'Video Consultation',
      time: 'Today · 12:15 PM',
      initialSeconds: 2525, // 42:05
    ),
  ];

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
            icon: Icon(Icons.calendar_today_outlined, color: textPrimary, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _consultations.length,
        itemBuilder: (context, index) {
          return _buildConsultationCard(_consultations[index]);
        },
      ),
    );
  }

  Widget _buildConsultationCard(Consultation consultation) {
    bool isVideo = consultation.type.contains('Video');
    Color typeColor = isVideo ? videoColor : audioColor;
    IconData typeIcon = isVideo ? Icons.videocam : Icons.phone;

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
                        consultation.patientName.split(' ').map((e) => e[0]).take(2).join(''),
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
                            consultation.patientName,
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
                                consultation.type,
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
                            consultation.time,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _CountdownBadge(initialSeconds: consultation.initialSeconds),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          PatientData patientData;
                          if (consultation.patientName.contains('Ramesh')) {
                            patientData = PatientData.getDummyRamesh();
                          } else if (consultation.patientName.contains('Sunita')) {
                            patientData = PatientData.getDummySunita();
                          } else {
                            patientData = PatientData.getDummySarah();
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PatientDetailsScreen(patient: patientData),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Color(0xFFE5E7EB)),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MyPatientsScreen()),
                          );
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
                          isVideo ? 'Start Video Call' : 'Start Audio Call',
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
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
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
