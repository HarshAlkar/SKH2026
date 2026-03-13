import 'package:flutter/material.dart';
import '../models/consultation_model.dart';
import '../widgets/consultation_card.dart';
import '../widgets/consultation_form.dart';
import 'consultation_details_screen.dart';
import '../../asha_worker/widgets/asha_drawer.dart';

class ConsultDoctorScreen extends StatefulWidget {
  const ConsultDoctorScreen({super.key});

  @override
  State<ConsultDoctorScreen> createState() => _ConsultDoctorScreenState();
}

class _ConsultDoctorScreenState extends State<ConsultDoctorScreen> {
  final List<ConsultationModel> _recentConsultations = [
    ConsultationModel(
      id: '1',
      doctorName: 'Dr. Sharma',
      symptoms:
          'Patient reporting persistent chest pain and mild dizziness for the last 2 hours.',
      urgencyLevel: UrgencyLevel.urgent,
      consultationType: ConsultationType.video,
      status: ConsultationStatus.pending,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    ConsultationModel(
      id: '2',
      doctorName: 'Dr. Patil',
      symptoms:
          'Child with high fever (103F) and cough. No response to basic paracetamol.',
      urgencyLevel: UrgencyLevel.moderate,
      consultationType: ConsultationType.audio,
      status: ConsultationStatus.adviceProvided,
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      doctorAdvice:
          "Monitor temperature every 4 hours and ensure hydration. Administer prescribed syrup if fever persists above 101F.",
    ),
  ];

  final Color primaryColor = const Color(0xFF2F4DB6);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  void _addConsultationRequest(ConsultationModel request) {
    setState(() {
      _recentConsultations.insert(0, request);
    });
  }

  void _navigateToDetails(ConsultationModel consultation) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ConsultationDetailsScreen(consultation: consultation),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: const AshaDrawer(),
      appBar: AppBar(
        title: const Text(
          "Consult Doctor",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: const [SizedBox(width: 8)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FORM SECTION
            ConsultationForm(onSubmit: _addConsultationRequest),
            const SizedBox(height: 32),

            // RECENT CONSULTATIONS TITLE
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

            // LIST SECTION
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentConsultations.length,
              itemBuilder: (context, index) {
                final consultation = _recentConsultations[index];
                return ConsultationCard(
                  consultation: consultation,
                  onTap: () => _navigateToDetails(consultation),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
