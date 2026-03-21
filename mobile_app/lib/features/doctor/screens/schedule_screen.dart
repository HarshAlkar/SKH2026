import 'package:flutter/material.dart';
import 'video_consultation_screen.dart';
import 'audio_consultation_screen.dart';
import 'patient_details_screen.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF1F2937);
    const backgroundColor = Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Today\'s Schedule',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, color: textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(),
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
    );
  }

  Widget _buildDateHeader() {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saturday · Mar 14, 2026',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
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

  Widget _buildAppointmentCard(BuildContext context, Appointment appointment) {
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
                  appointment.time,
                  style: const TextStyle(
                    color: Color(0xFF2A7DE1),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFF1F5F9),
                      child: appointment.avatarUrl != null
                          ? null
                          : const Icon(Icons.person, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.patientName,
                            style: const TextStyle(
                              color: textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Age: ${appointment.age} · Village: ${appointment.village}',
                            style: const TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildTypeBadge(appointment.type),
                  ],
                ),
                const SizedBox(height: 16),
                _buildHistorySection(appointment),
                const SizedBox(height: 16),
                _buildActionButtons(context, appointment),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(ConsultationType type) {
    Color color;
    IconData icon;
    String label;

    switch (type) {
      case ConsultationType.video:
        color = const Color(0xFF2563EB);
        icon = Icons.videocam;
        label = 'Video Call';
        break;
      case ConsultationType.audio:
        color = const Color(0xFF10B981);
        icon = Icons.phone;
        label = 'Audio Call';
        break;
      case ConsultationType.offline:
        color = const Color(0xFFF59E0B);
        icon = Icons.local_hospital;
        label = 'Offline Visit';
        break;
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

  Widget _buildHistorySection(Appointment appointment) {
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
            appointment.historySummary,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (appointment.lastPrescription != null) ...[
            const SizedBox(height: 6),
            Text(
              'Last Prescription: ${appointment.lastPrescription}',
              style: const TextStyle(
                color: Color(0xFF2A7DE1),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Appointment appointment) {
    switch (appointment.type) {
      case ConsultationType.video:
        return SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VideoConsultationScreen(
                    consultationId: '', // Should be fixed to actual ID later if needed
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
      case ConsultationType.audio:
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
      case ConsultationType.offline:
        return SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PatientDetailsScreen(patient: appointment.patientData),
                ),
              );
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

enum ConsultationType { video, audio, offline }

class Appointment {
  final String time;
  final String patientName;
  final String age;
  final String village;
  final ConsultationType type;
  final String historySummary;
  final String? lastPrescription;
  final String? avatarUrl;
  final PatientData patientData;

  Appointment({
    required this.time,
    required this.patientName,
    required this.age,
    required this.village,
    required this.type,
    required this.historySummary,
    this.lastPrescription,
    this.avatarUrl,
    required this.patientData,
  });
}

final List<Appointment> _appointments = [
  Appointment(
    time: '10:30 AM',
    patientName: 'Sarah Jenkins',
    age: '28',
    village: 'Green Valley',
    type: ConsultationType.video,
    historySummary: 'Upper respiratory infection\nLast visit: Oct 10',
    lastPrescription: 'Amoxicillin 500mg for 5 days',
    patientData: PatientData.getDummySarah(),
  ),
  Appointment(
    time: '11:15 AM',
    patientName: 'Ramesh Patil',
    age: '45',
    village: 'Kaman Village',
    type: ConsultationType.audio,
    historySummary: 'Chronic cough treatment',
    patientData: PatientData.getDummyRamesh(),
  ),
  Appointment(
    time: '12:30 PM',
    patientName: 'Sunita Deshmukh',
    age: '32',
    village: 'Pelhar',
    type: ConsultationType.offline,
    historySummary: 'Back pain physiotherapy follow-up',
    patientData: PatientData.getDummySunita(),
  ),
  Appointment(
    time: '02:00 PM',
    patientName: 'Lata Bai',
    age: '56',
    village: 'Mumbai South',
    type: ConsultationType.video,
    historySummary: 'Blood pressure monitoring',
    patientData: PatientData.getDummyAmitabh(), // Using Amitabh as proxy for dummy Lata
  ),
];
