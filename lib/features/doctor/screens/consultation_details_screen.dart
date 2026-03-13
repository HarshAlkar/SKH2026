import 'package:flutter/material.dart';
import '../models/consultation_model.dart';
import 'package:intl/intl.dart';

class ConsultationDetailsScreen extends StatelessWidget {
  final ConsultationModel consultation;

  const ConsultationDetailsScreen({super.key, required this.consultation});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2F4DB6);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Consultation Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DOCTOR & STATUS CARD
            Container(
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
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: primaryColor.withOpacity(0.1),
                        child: const Icon(
                          Icons.person,
                          color: primaryColor,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              consultation.doctorName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              "Requested: ${DateFormat('MMM dd, hh:mm a').format(consultation.timestamp)}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(consultation.status),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDetailIcon(
                        Icons.video_call_outlined,
                        consultation.consultationType.name.toUpperCase(),
                      ),
                      _buildDetailIcon(
                        Icons.priority_high_outlined,
                        consultation.urgencyLevel.name.toUpperCase(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SYMPTOMS SECTION
            _buildSection(
              title: "Patient Symptoms",
              content: consultation.symptoms,
              icon: Icons.personal_injury_outlined,
            ),
            const SizedBox(height: 20),

            // DOCTOR ADVICE SECTION
            if (consultation.status == ConsultationStatus.adviceProvided)
              _buildSection(
                title: "Doctor's Advice",
                content: consultation.doctorAdvice ?? "No advice provided yet.",
                icon: Icons.medical_services_outlined,
                contentColor: Colors.blue[900],
                bgColor: primaryColor.withOpacity(0.05),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.timer_outlined, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Waiting for doctor's response. You will be notified once advice is provided.",
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (consultation.attachedFileName != null) ...[
              const SizedBox(height: 20),
              _buildSection(
                title: "Attached Report",
                content: consultation.attachedFileName!,
                icon: Icons.attach_file,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ConsultationStatus status) {
    bool isPending = status == ConsultationStatus.pending;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isPending ? Colors.orange : Colors.green).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isPending ? "Pending" : "Advice Provided",
        style: TextStyle(
          color: isPending ? Colors.orange : Colors.green,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required IconData icon,
    Color? contentColor,
    Color? bgColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: bgColor == null
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              color: contentColor ?? Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
