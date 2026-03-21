import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/consultation_provider.dart';
import '../../../providers/auth_provider.dart';
import 'patient_details_screen.dart';
import 'video_consultation_screen.dart';
import 'consultation_history_screen.dart';
import 'dart:async';

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

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConsultationProvider>().fetchUpcomingConsultations();
      context.read<ConsultationProvider>().fetchHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            icon: Icon(Icons.history, color: textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConsultationHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ConsultationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.upcomingConsultations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final upcoming = provider.upcomingConsultations.where((c) {
            final name = c['patient_name']?.toString().toLowerCase() ?? '';
            return name.contains(_searchQuery.toLowerCase());
          }).toList();

          return Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await provider.fetchUpcomingConsultations();
                    await provider.fetchHistory();
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (upcoming.isNotEmpty) ...[
                        ...upcoming.map((c) => _buildConsultationCard(c, isUpcoming: true)),
                      ],
                      if (upcoming.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 100),
                            child: Column(
                              children: [
                                Icon(Icons.search_off, size: 64, color: textSecondary.withOpacity(0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  'No consultations found',
                                  style: TextStyle(color: textSecondary, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search patients...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: lightBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildConsultationCard(Map<String, dynamic> consultation, {required bool isUpcoming}) {
    final String patientName = consultation['patient_name'] ?? 'Unknown Patient';
    final String type = consultation['call_type'] ?? 'VIDEO';
    final String consultationId = consultation['id'].toString();
    final String patientId = consultation['patient'].toString();
    final DateTime createdAt = DateTime.parse(consultation['created_at'] ?? DateTime.now().toIso8601String());
    
    // Simulate a scheduled time for the UI since the backend doesn't explicitly have it right now
    // Just add 30 minutes to created_at for upcoming, or show the actual time for history
    final DateTime scheduledTime = isUpcoming ? DateTime.now().add(const Duration(minutes: 30)) : createdAt;
    
    bool isVideo = type == 'VIDEO';
    Color typeColor = isVideo ? videoColor : audioColor;
    IconData typeIcon = isVideo ? Icons.videocam : Icons.phone;
    
    // Format date string
    String dateString = 'Today';
    if (scheduledTime.day != DateTime.now().day) {
      dateString = '${scheduledTime.day}/${scheduledTime.month}/${scheduledTime.year}';
    }
    
    int hour = scheduledTime.hour > 12 ? scheduledTime.hour - 12 : (scheduledTime.hour == 0 ? 12 : scheduledTime.hour);
    String amPm = scheduledTime.hour >= 12 ? 'PM' : 'AM';
    String timeString = '$hour:${scheduledTime.minute.toString().padLeft(2, '0')} $amPm';

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
                        patientName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(''),
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
                            patientName,
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
                                isVideo ? 'Video Consultation' : 'Audio Consultation',
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
                            '$dateString • $timeString',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.healing, size: 14, color: textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Symptoms: ${consultation['recent_symptoms'] ?? 'None reported'}',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isUpcoming) 
                      _CountdownBadge(
                        initialSeconds: scheduledTime.difference(DateTime.now()).inSeconds > 0 
                            ? scheduledTime.difference(DateTime.now()).inSeconds 
                            : 0,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          final patientDetails = consultation['patient_details'];
                          if (patientDetails != null) {
                            final patientData = PatientData.fromJson(patientDetails);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PatientDetailsScreen(patient: patientData),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Patient details not available')),
                            );
                          }
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
                    if (isUpcoming)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final doctorName = context.read<AuthProvider>().user?.name ?? 'Doctor';
                          context.read<ConsultationProvider>().startConsultation(
                            consultationId: consultationId,
                            patientId: patientId,
                            patientName: patientName,
                            doctorName: doctorName,
                            isVideo: isVideo,
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
    if (totalSeconds <= 0) return '00:00';
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Returning an empty SizedBox since the previous code was commented out
    return const SizedBox.shrink();
  }
}
