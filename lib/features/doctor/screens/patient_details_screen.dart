import 'package:flutter/material.dart';
import 'video_consultation_screen.dart';

class PatientDetailsScreen extends StatelessWidget {
  const PatientDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2A7DE1);
    const textPrimary = Color(0xFF1F2937);
    const textSecondary = Color(0xFF6B7280);
    const cardBg = Color(0xFFFFFFFF);
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
            backgroundColor: Color(0xFFE8F1FF), // Light Blue
            child: Icon(Icons.person, size: 50, color: primaryBlue),
            // Placeholder for the actual image. The design uses an image, but
            // keeping an icon fallback. We'll add a clip behavior if image was provided.
          ),
          const SizedBox(height: 16),
          const Text(
            'Sarah Jenkins',
            style: TextStyle(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Female',
                  style: TextStyle(
                    color: primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '28 years old',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: textSecondary),
              SizedBox(width: 4),
              Text(
                'Village: Green Valley, North District',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VideoConsultationScreen(),
                ),
              );
            },
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
            onPressed: () {},
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
      ],
    );
  }

  Widget _buildPersonalInfoCard() {
    return _buildCardBase(
      title: 'Personal Info',
      iconUrl: Icons.person_outline,
      child: Column(
        children: [
          _buildInfoRow('Full Name', 'Sarah Jenkins'),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildInfoRow('Age', '28'),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildInfoRow('Location', 'Green Valley, Sector 4'),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildInfoRow('Blood Type', 'O Positive'),
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
            'No known chronic conditions reported.',
          ),
          const SizedBox(height: 12),
          _buildHistorySection('PAST SURGERIES', 'Appendectomy (2018)'),
          const SizedBox(height: 12),
          _buildHistorySection('ALLERGIES', 'Penicillin, Peanuts'),
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
            children: [
              _buildSymptomChip(
                'High Fever (102°F)',
                const Color(0xFFFFE4E6),
                const Color(0xFFE11D48),
              ),
              _buildSymptomChip(
                'Persistent Cough',
                const Color(0xFFFFEDD5),
                const Color(0xFFEA580C),
              ),
              _buildSymptomChip(
                'Shortness of breath',
                const Color(0xFFF1F5F9),
                const Color(0xFF475569),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // AI Insights Panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 13,
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text: 'AI Insights: ',
                    style: TextStyle(
                      color: Color(0xFF2A7DE1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text:
                        'Symptoms reported 48 hours ago. Pattern suggests upper respiratory infection. Recommended immediate vitals check and chest auscultation.',
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
              color: Color(0xFF3B82F6), // Blue 500
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              color: Color(0xFF334155), // Slate 700
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
