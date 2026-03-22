import 'package:flutter/material.dart';
import 'package:hs053/core/widgets/common_appbar.dart';
import 'package:hs053/core/routes/app_routes.dart';
import 'package:hs053/features/asha_worker/widgets/asha_drawer.dart';
import 'package:hs053/shared/models/consultation_model.dart';
import '../widgets/consultation_card.dart';
import 'request_consultation_screen.dart';

class ConsultDoctorScreen extends StatefulWidget {
  const ConsultDoctorScreen({super.key});

  @override
  State<ConsultDoctorScreen> createState() => _ConsultDoctorScreenState();
}

class _ConsultDoctorScreenState extends State<ConsultDoctorScreen> {
  final Color primaryColor = const Color(0xFF2F4DB6);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  // Mock recent consultations
  final List<ConsultationModel> _recentConsultations = [
    ConsultationModel(
      id: "1",
      doctorName: "Dr. Sharma",
      patientName: "Ramesh Patil",
      symptoms: "High Fever",
      urgency: UrgencyLevel.urgent,
      type: ConsultationType.videoCall,
      status: ConsultationStatus.pending,
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    ConsultationModel(
      id: "2",
      doctorName: "Dr. Patil",
      patientName: "Shanti Devi",
      symptoms: "Stable BP",
      urgency: UrgencyLevel.normal,
      type: ConsultationType.chatMessage,
      status: ConsultationStatus.adviceProvided,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const CommonAppBar(
        title: "Consult Doctor",
        showProfile: true,
      ),
      drawer: const AshaDrawer(currentRoute: AppRoutes.ashaConsultDoctor),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Telemedicine Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Remote Doctor Consultation",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Connect with a certified doctor to review patient symptoms and receive medical guidance.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.video_camera_front_outlined,
                        color: primaryColor,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Button
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RequestConsultationScreen(),
                    ),
                  );

                  if (result != null && result is ConsultationModel) {
                    setState(() {
                      _recentConsultations.insert(0, result);
                    });
                  }
                },
                icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                label: const Text(
                  "Request Doctor Consultation",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Recent Consultations
              const Text(
                "RECENT CONSULTATIONS",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              ..._recentConsultations.map(
                (c) => ConsultationCard(consultation: c),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
