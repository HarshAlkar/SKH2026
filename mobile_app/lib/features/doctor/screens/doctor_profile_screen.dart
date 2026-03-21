import 'package:flutter/material.dart';

class DoctorProfileScreen extends StatelessWidget {
  const DoctorProfileScreen({super.key});

  final Color primaryBlue = const Color(0xFF2A7DE1);
  final Color lightBg = const Color(0xFFF3F4F6);
  final Color cardBg = const Color(0xFFFFFFFF);
  final Color accentGreen = const Color(0xFF22C55E);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);

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
          'Doctor Profile',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildProfessionalInfo(),
                  const SizedBox(height: 16),
                  _buildClinicInfo(),
                  const SizedBox(height: 16),
                  _buildConsultationStats(),
                  const SizedBox(height: 16),
                  _buildContactInfo(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryBlue.withOpacity(0.1), width: 4),
                  color: primaryBlue.withOpacity(0.05),
                ),
                child: Center(
                  child: Icon(Icons.person, size: 60, color: primaryBlue.withOpacity(0.5)),
                ),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: accentGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Dr. Amit Sharma',
            style: TextStyle(
              color: textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'General Physician',
            style: TextStyle(
              color: primaryBlue,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: textSecondary),
              const SizedBox(width: 4),
              Text(
                'Green Valley Health Center',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalInfo() {
    return _buildSectionCard(
      title: 'Professional Information',
      children: [
        _buildInfoRow(Icons.badge_outlined, 'Medical License', 'MC-345897'),
        _buildInfoRow(Icons.work_outline, 'Experience', '12 Years'),
        _buildInfoRow(Icons.school_outlined, 'Education', 'MBBS, MD (Internal Medicine)'),
        _buildInfoRow(Icons.videocam_outlined, 'Consultation Mode', 'Video · Audio · Offline'),
      ],
    );
  }

  Widget _buildClinicInfo() {
    return _buildSectionCard(
      title: 'Clinic Information',
      children: [
        _buildInfoRow(Icons.local_hospital_outlined, 'Clinic Name', 'Green Valley Health Center'),
        _buildInfoRow(Icons.map_outlined, 'Location', 'Kaman Village, Vasai Region'),
        _buildInfoRow(Icons.access_time, 'Working Hours', '09:00 AM – 05:00 PM'),
      ],
    );
  }

  Widget _buildConsultationStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Consultation Stats',
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(child: _buildStatItem('Total Patients', '1,248', primaryBlue)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatItem('Monthly', '152', Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatItem('Rating', '4.8 ★', accentGreen)),
          ],
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    return _buildSectionCard(
      title: 'Contact Information',
      children: [
        _buildInfoRow(Icons.phone_outlined, 'Phone Number', '+91 98765 43210'),
        _buildInfoRow(Icons.email_outlined, 'Email', 'dr.amitsharma@vitalreach.com'),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: primaryBlue.withOpacity(0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: textSecondary, fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

}
