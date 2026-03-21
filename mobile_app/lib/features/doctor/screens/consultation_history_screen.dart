import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/doctor_navigation_drawer.dart';
import '../../../providers/consultation_provider.dart';
import 'package:intl/intl.dart';

class ConsultationRecord {
  final int id;
  final String patientName;
  final int age;
  final String village;
  final String date;
  final String status;
  final String prescriptionSummary;

  ConsultationRecord({
    required this.id,
    required this.patientName,
    required this.age,
    required this.village,
    required this.date,
    required this.status,
    required this.prescriptionSummary,
  });

  factory ConsultationRecord.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    if (json['created_at'] != null) {
      createdAt = DateTime.parse(json['created_at']);
    }
    
    return ConsultationRecord(
      id: json['id'] ?? 0,
      patientName: json['patient_name'] ?? 'Unknown',
      age: json['patient_age'] ?? 0,
      village: json['patient_village'] ?? 'Unknown',
      date: createdAt != null ? DateFormat('MMM dd, yyyy').format(createdAt) : 'N/A',
      status: json['status'] ?? 'Unknown',
      prescriptionSummary: json['prescription_summary'] ?? 'No prescription',
    );
  }
}

class ConsultationHistoryScreen extends StatefulWidget {
  const ConsultationHistoryScreen({super.key});

  @override
  State<ConsultationHistoryScreen> createState() => _ConsultationHistoryScreenState();
}

class _ConsultationHistoryScreenState extends State<ConsultationHistoryScreen> {
  final Color primaryBlue = const Color(0xFF2A7DE1);
  final Color lightBg = const Color(0xFFF3F4F6);
  final Color cardBg = const Color(0xFFFFFFFF);
  final Color videoColor = const Color(0xFF2563EB);
  final Color audioColor = const Color(0xFF10B981);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConsultationProvider>().fetchHistory();
      context.read<ConsultationProvider>().fetchUpcomingConsultations();
    });
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
          'Consultation History',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<ConsultationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.history.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final completed = provider.history;
          return _buildList(completed, isUpcoming: false);
        },
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, {required bool isUpcoming}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No consultations found',
              style: TextStyle(color: textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildConsultationCard(items[index], isUpcoming: isUpcoming);
      },
    );
  }

  Widget _buildConsultationCard(Map<String, dynamic> consultation, {required bool isUpcoming}) {
    final String patientName = consultation['patient_name'] ?? 'Unknown Patient';
    final String type = consultation['call_type'] ?? 'VIDEO';
    final String status = consultation['status'] ?? (isUpcoming ? 'PENDING' : 'COMPLETED');
    final String patientId = consultation['patient'].toString();
    final DateTime createdAt = DateTime.parse(consultation['created_at'] ?? DateTime.now().toIso8601String());
    
    // Simulate a scheduled time for the UI since the backend doesn't explicitly have it right now
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
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUpcoming ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: isUpcoming ? const Color(0xFFD97706) : const Color(0xFF059669),
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
                          // View details
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
