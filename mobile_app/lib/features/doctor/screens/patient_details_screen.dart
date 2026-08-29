import 'package:flutter/material.dart';
import '../../../core/services/call_launcher.dart';
import '../../chat/screens/chat_screen.dart';
import 'create_prescription_screen.dart';


class PatientData {
  final String name;
  final String age;
  final String gender;
  final String village;
  final String bloodType;
  final String phoneNumber;
  final String chronicConditions;
  final String pastSurgeries;
  final String allergies;
  final List<SymptomData> symptoms;
  final String aiInsights;
  final int? userId;
  final int? patientId;

  PatientData({
    required this.name,
    required this.age,
    required this.gender,
    required this.village,
    required this.bloodType,
    this.phoneNumber = '',
    required this.chronicConditions,
    required this.pastSurgeries,
    required this.allergies,
    required this.symptoms,
    required this.aiInsights,
    this.userId,
    this.patientId,
  });
}


class SymptomData {
  final String label;
  final Color bgColor;
  final Color textColor;

  SymptomData({required this.label, required this.bgColor, required this.textColor});
}

class PatientDetailsScreen extends StatelessWidget {
  final PatientData patient;

  const PatientDetailsScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF1F2937);
    const backgroundColor = Color(0xFFF8FAFC);

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
          'Patient Details',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            _buildProfileCard(),
            const SizedBox(height: 20),
            _buildActionButtons(context),
            const SizedBox(height: 20),
            _buildPersonalInfoCard(),
            const SizedBox(height: 20),
            _buildHealthHistoryCard(),
            const SizedBox(height: 20),
            _buildSymptomsCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    const primaryBlue = Color(0xFF2A7DE1);
    const textPrimary = Color(0xFF1F2937);
    const textSecondary = Color(0xFF6B7280);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFFE8F1FF),
            child: Icon(Icons.person, size: 50, color: primaryBlue),
          ),
          const SizedBox(height: 16),
          Text(
            patient.name,
            style: const TextStyle(
              color: textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  patient.gender,
                  style: const TextStyle(
                    color: primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${patient.age} years old',
                  style: const TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: textSecondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Village: ${patient.village}',
                  style: const TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _startCall(BuildContext context, {required bool isVideo}) async {
    final userId = patient.userId;
    if (userId == null || userId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This patient cannot receive a call yet (missing user id).')),
      );
      return;
    }
    await CallLauncher.start(
      context: context,
      peerName: patient.name,
      receiverUserId: userId.toString(),
      isVideo: isVideo,
      patientId: patient.patientId ?? userId,
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    const primaryBlue = Color(0xFF2A7DE1);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => _startCall(context, isVideo: true),
            icon: const Icon(Icons.videocam_outlined, size: 20),
            label: const Text(
              'Start Video Consultation',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _startCall(context, isVideo: false),
            icon: const Icon(
              Icons.phone_outlined,
              size: 20,
              color: primaryBlue,
            ),
            label: const Text(
              'Start Audio Call',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: primaryBlue, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              final userId = patient.userId;
              if (userId == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    peerUserId: userId,
                    peerName: patient.name,
                    peerPhone: patient.phoneNumber,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline, size: 20),
            label: const Text(
              'Chat with Patient',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F766E),
              side: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreatePrescriptionScreen(
                    patientName: patient.name,
                    patientId: (patient.patientId ?? patient.userId)?.toString(),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.assignment_outlined, size: 20),
            label: const Text(
              'Create Prescription',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoCard() {
    return _buildCardBase(
      title: 'Personal Info',
      iconUrl: Icons.person_outline,
      child: Column(
        children: [
          _buildInfoRow('Full Name', patient.name),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildInfoRow('Age', patient.age),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildInfoRow('Location', patient.village),
          if (patient.phoneNumber.isNotEmpty) ...[
            const Divider(height: 24, color: Color(0xFFF1F5F9)),
            _buildInfoRow('Phone', patient.phoneNumber),
          ],
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildInfoRow('Blood Type', patient.bloodType),
        ],
      ),
    );
  }

  Widget _buildHealthHistoryCard() {
    return _buildCardBase(
      title: 'Health History',
      iconUrl: Icons.history,
      child: Column(
        children: [
          _buildHistorySection(
            'CHRONIC CONDITIONS',
            patient.chronicConditions,
          ),
          const SizedBox(height: 12),
          _buildHistorySection('PAST SURGERIES', patient.pastSurgeries),
          const SizedBox(height: 12),
          _buildHistorySection('ALLERGIES', patient.allergies),
        ],
      ),
    );
  }

  Widget _buildSymptomsCard() {
    return _buildCardBase(
      title: 'Symptoms',
      iconUrl: Icons.medical_services_outlined,
      titleBadge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF2A7DE1).withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'AI ANALYZED',
          style: TextStyle(
            color: Color(0xFF2A7DE1),
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: patient.symptoms.map((s) => _buildSymptomChip(s.label, s.bgColor, s.textColor)).toList(),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 13,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(
                    text: 'AI Insights: ',
                    style: TextStyle(
                      color: Color(0xFF2A7DE1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: patient.aiInsights,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBase({
    required String title,
    required IconData iconUrl,
    Widget? titleBadge,
    required Widget child,
  }) {
    const primaryBlue = Color(0xFF2A7DE1);
    const textPrimary = Color(0xFF1F2937);

    return Container(
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
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconUrl, color: primaryBlue, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (titleBadge != null) ...[const SizedBox(width: 8), titleBadge],
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection(String title, String content) {
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
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF3B82F6),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
