import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';

class DoctorSettingsScreen extends StatefulWidget {
  const DoctorSettingsScreen({super.key});

  @override
  State<DoctorSettingsScreen> createState() => _DoctorSettingsScreenState();
}

class _DoctorSettingsScreenState extends State<DoctorSettingsScreen> {
  // Toggle states
  bool _twoFactorEnabled = false;
  bool _consultationRequestsEnabled = true;
  bool _emergencyAlertsEnabled = true;
  bool _prescriptionUpdatesEnabled = true;
  bool _autoSwitchToAudio = true;

  // Dropdown values
  String _defaultConsultationType = 'Video Call';
  String _consultationDuration = '15 minutes';
  String _appLanguage = 'English';

  // Slider value
  double _fontSize = 1.0; // 0.0: Small, 1.0: Medium, 2.0: Large

  final Color primaryBlue = const Color(0xFF2A7DE1);
  final Color lightBg = const Color(0xFFF3F4F6);
  final Color cardBg = const Color(0xFFFFFFFF);
  final Color accentGreen = const Color(0xFF22C55E);
  final Color warningRed = const Color(0xFFEF4444);
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
          'Settings',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: primaryBlue.withOpacity(0.1),
              child: Icon(Icons.person, size: 20, color: primaryBlue),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(),
            const SizedBox(height: 24),
            _buildSectionTitle('ACCOUNT SETTINGS'),
            _buildSettingsCard([
              _buildSettingsTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: () {
                  // Navigate to change_password_screen.dart
                },
              ),
              _buildSettingsToggle(
                icon: Icons.security,
                title: 'Two-Factor Authentication',
                value: _twoFactorEnabled,
                onChanged: (val) => setState(() => _twoFactorEnabled = val),
              ),
              _buildSettingsTile(
                icon: Icons.important_devices,
                title: 'Manage Login Devices',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionTitle('NOTIFICATIONS'),
            _buildSettingsCard([
              _buildSettingsToggle(
                icon: Icons.chat_bubble_outline,
                title: 'Consultation Requests',
                value: _consultationRequestsEnabled,
                onChanged: (val) => setState(() => _consultationRequestsEnabled = val),
              ),
              _buildSettingsToggle(
                icon: Icons.emergency_outlined,
                title: 'Emergency Alerts',
                value: _emergencyAlertsEnabled,
                onChanged: (val) => setState(() => _emergencyAlertsEnabled = val),
              ),
              _buildSettingsToggle(
                icon: Icons.assignment_outlined,
                title: 'Prescription Updates',
                value: _prescriptionUpdatesEnabled,
                onChanged: (val) => setState(() => _prescriptionUpdatesEnabled = val),
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionTitle('CONSULTATION PREFERENCES'),
            _buildSettingsCard([
              _buildSettingsDropdown(
                icon: Icons.video_camera_front_outlined,
                title: 'Default Consultation Type',
                value: _defaultConsultationType,
                items: ['Video Call', 'Audio Call', 'Chat Consultation'],
                onChanged: (val) => setState(() => _defaultConsultationType = val!),
              ),
              _buildSettingsToggle(
                icon: Icons.network_check,
                title: 'Auto Switch to Audio',
                subtitle: 'Switch if network is poor',
                value: _autoSwitchToAudio,
                onChanged: (val) => setState(() => _autoSwitchToAudio = val),
              ),
              _buildSettingsDropdown(
                icon: Icons.timer_outlined,
                title: 'Consultation Duration Limit',
                value: _consultationDuration,
                items: ['15 minutes', '30 minutes', '45 minutes'],
                onChanged: (val) => setState(() => _consultationDuration = val!),
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionTitle('LANGUAGE & ACCESSIBILITY'),
            _buildSettingsCard([
              _buildSettingsDropdown(
                icon: Icons.language,
                title: 'App Language',
                value: _appLanguage,
                items: ['English', 'Hindi', 'Marathi'],
                onChanged: (val) => setState(() => _appLanguage = val!),
              ),
              _buildSettingsSlider(
                icon: Icons.format_size,
                title: 'Font Size',
                value: _fontSize,
                onChanged: (val) => setState(() => _fontSize = val),
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionTitle('PRIVACY & DATA'),
            _buildSettingsCard([
              _buildSettingsTile(
                icon: Icons.verified_user_outlined,
                title: 'Patient Data Security',
                trailing: Text(
                  'HIPAA Compliant',
                  style: TextStyle(color: accentGreen, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              _buildSettingsTile(
                icon: Icons.file_download_outlined,
                title: 'Download Medical Reports',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionTitle('HELP & SUPPORT'),
            _buildSettingsCard([
              _buildSettingsTile(
                icon: Icons.headset_mic_outlined,
                title: 'Contact Support',
                onTap: () {},
              ),
              _buildSettingsTile(
                icon: Icons.bug_report_outlined,
                title: 'Report a Bug',
                onTap: () {},
              ),
              _buildSettingsTile(
                icon: Icons.info_outline,
                title: 'App Version',
                trailing: Text(
                  'v2.1.0',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
              ),
            ]),
            const SizedBox(height: 32),
            _buildLogoutButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
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
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, size: 40, color: primaryBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. Amit Sharma',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'General Physician',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Green Valley Health Center',
                  style: TextStyle(
                    color: textSecondary.withOpacity(0.8),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: lightBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: textPrimary),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing ?? Icon(Icons.chevron_right, size: 20, color: textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildSettingsToggle({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: lightBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: textPrimary),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: textSecondary)) : null,
      activeThumbColor: primaryBlue,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildSettingsDropdown({
    required IconData icon,
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: lightBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: textPrimary),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: TextStyle(fontSize: 13, color: textSecondary)),
            );
          }).toList(),
          elevation: 1,
          icon: Icon(Icons.keyboard_arrow_down, size: 18, color: textSecondary),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildSettingsSlider({
    required IconData icon,
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: lightBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: textPrimary),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(60, 0, 16, 16),
          child: Row(
            children: [
              const Text('A', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              Expanded(
                child: Slider(
                  value: value,
                  min: 0,
                  max: 2,
                  divisions: 2,
                  activeColor: primaryBlue,
                  onChanged: onChanged,
                ),
              ),
              const Text('A', style: TextStyle(fontSize: 18, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.roleSelection,
            (route) => false,
          );
        },
        icon: const Icon(Icons.logout, size: 20),
        label: const Text(
          'Logout Account',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: warningRed,
          side: BorderSide(color: warningRed, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
