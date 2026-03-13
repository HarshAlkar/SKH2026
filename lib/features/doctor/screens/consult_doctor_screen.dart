import 'package:flutter/material.dart';
import '../models/consultation_model.dart';
import '../widgets/consultation_card.dart';
import '../widgets/patient_selector.dart';
import '../widgets/consultation_form.dart';
import '../../asha_worker/widgets/asha_drawer.dart';

class ConsultDoctorScreen extends StatefulWidget {
  const ConsultDoctorScreen({super.key});

  @override
  State<ConsultDoctorScreen> createState() => _ConsultDoctorScreenState();
}

class _ConsultDoctorScreenState extends State<ConsultDoctorScreen> {
  final Color primaryColor = const Color(0xFF2F4DB6);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  String? _selectedPatientName;
  bool _isLoading = false;

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

  void _handleConsultationRequest(Map<String, dynamic> data) async {
    if (_selectedPatientName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a patient first")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Doctor consultation request sent successfully"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          "Consult Doctor",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              backgroundColor: Colors.white24,
              radius: 16,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
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

                  // Patient Selector
                  PatientSelector(
                    onPatientSelected: (name) =>
                        setState(() => _selectedPatientName = name),
                  ),

                  const SizedBox(height: 24),

                  // Consultation Form
                  const Text(
                    "CONSULTATION DETAILS",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConsultationForm(onSubmit: _handleConsultationRequest),

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
          if (_isLoading)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      drawer: const AshaDrawer(),
    );
  }
}
