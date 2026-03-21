import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'change_password_screen.dart';
import '../../../core/utils/app_translations.dart';
import '../../../core/providers/settings_provider.dart';
import '../services/settings_service.dart';
import 'package:hs053/features/user/services/doctor_service.dart';
import '../../../core/utils/helpers.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_routes.dart';

class DoctorSettingsScreen extends StatefulWidget {
  const DoctorSettingsScreen({super.key});

  @override
  State<DoctorSettingsScreen> createState() => _DoctorSettingsScreenState();
}

class _DoctorSettingsScreenState extends State<DoctorSettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final DoctorService _doctorService = DoctorService();
  
  bool _isLoading = true;
  Map<String, dynamic>? _doctorData;

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
  double _fontSize = 1.0;

  final Color primaryBlue = const Color(0xFF2A7DE1);
  final Color lightBg = const Color(0xFFF3F4F6);
  final Color cardBg = const Color(0xFFFFFFFF);
  final Color accentGreen = const Color(0xFF22C55E);
  final Color warningRed = const Color(0xFFEF4444);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final docProfile = await _doctorService.getDoctorProfile();
      final settings = await _settingsService.getSettings();
      
      if (mounted) {
        setState(() {
          _doctorData = docProfile;
          if (settings != null) {
            _twoFactorEnabled = settings['two_factor_enabled'] ?? false;
            _consultationRequestsEnabled = settings['consultation_requests_enabled'] ?? true;
            _emergencyAlertsEnabled = settings['emergency_alerts_enabled'] ?? true;
            _prescriptionUpdatesEnabled = settings['prescription_updates_enabled'] ?? true;
            _autoSwitchToAudio = settings['auto_switch_to_audio'] ?? true;
            _defaultConsultationType = settings['default_consultation_type'] ?? 'Video Call';
            _consultationDuration = settings['consultation_duration_limit'] ?? '15 minutes';
            _appLanguage = settings['app_language'] ?? 'English';
            _fontSize = (settings['font_size'] ?? 1.0).toDouble();
            
            // Update global settings provider
            final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
            settingsProvider.loadSettings(settings);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Helpers.showSnackBar(context, 'Failed to load settings', isError: true);
      }
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    final success = await _settingsService.updateSettings({key: value});
    if (!success && mounted) {
      Helpers.showSnackBar(context, 'failed_update'.tr(context), isError: true);
      _loadSettings(); // Reload to revert state
    } else if (success && mounted) {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      if (key == 'font_size') {
        settingsProvider.updateFontSize(value);
      } else if (key == 'app_language') {
        settingsProvider.updateLanguage(value);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: lightBg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
          'settings'.tr(context),
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSettings,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(),
              const SizedBox(height: 24),
              _buildSectionTitle('account_settings'.tr(context)),
              _buildSettingsCard([
                _buildSettingsTile(
                  icon: Icons.lock_outline,
                  title: 'change_password'.tr(context),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                    );
                  },
                ),
                _buildSettingsToggle(
                  icon: Icons.security,
                  title: 'two_factor'.tr(context),
                  value: _twoFactorEnabled,
                  onChanged: (val) {
                    setState(() => _twoFactorEnabled = val);
                    _updateSetting('two_factor_enabled', val);
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.important_devices,
                  title: 'manage_devices'.tr(context),
                  onTap: () {},
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle('notifications'.tr(context)),
              _buildSettingsCard([
                _buildSettingsToggle(
                  icon: Icons.chat_bubble_outline,
                  title: 'consultation_req'.tr(context),
                  value: _consultationRequestsEnabled,
                  onChanged: (val) {
                    setState(() => _consultationRequestsEnabled = val);
                    _updateSetting('consultation_requests_enabled', val);
                  },
                ),
                _buildSettingsToggle(
                  icon: Icons.emergency_outlined,
                  title: 'emergency_alerts'.tr(context),
                  value: _emergencyAlertsEnabled,
                  onChanged: (val) {
                    setState(() => _emergencyAlertsEnabled = val);
                    _updateSetting('emergency_alerts_enabled', val);
                  },
                ),
                _buildSettingsToggle(
                  icon: Icons.assignment_outlined,
                  title: 'prescription_updates'.tr(context),
                  value: _prescriptionUpdatesEnabled,
                  onChanged: (val) {
                    setState(() => _prescriptionUpdatesEnabled = val);
                    _updateSetting('prescription_updates_enabled', val);
                  },
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle('consultation_pref'.tr(context)),
              _buildSettingsCard([
                _buildSettingsDropdown(
                  icon: Icons.video_camera_front_outlined,
                  title: 'default_type'.tr(context),
                  value: _defaultConsultationType,
                  items: [
                    'video_call'.tr(context),
                    'audio_call'.tr(context),
                    'chat_consultation'.tr(context)
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _defaultConsultationType = val);
                      _updateSetting('default_consultation_type', val);
                    }
                  },
                ),
                _buildSettingsToggle(
                  icon: Icons.network_check,
                  title: 'auto_switch'.tr(context),
                  subtitle: 'poor_network'.tr(context),
                  value: _autoSwitchToAudio,
                  onChanged: (val) {
                    setState(() => _autoSwitchToAudio = val);
                    _updateSetting('auto_switch_to_audio', val);
                  },
                ),
                _buildSettingsDropdown(
                  icon: Icons.timer_outlined,
                  title: 'duration_limit'.tr(context),
                  value: _consultationDuration,
                  items: ['15 minutes', '30 minutes', '45 minutes'],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _consultationDuration = val);
                      _updateSetting('consultation_duration_limit', val);
                    }
                  },
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle('language_accessibility'.tr(context)),
              _buildSettingsCard([
                _buildSettingsDropdown(
                  icon: Icons.language,
                  title: 'app_language'.tr(context),
                  value: _appLanguage,
                  items: ['English', 'Hindi', 'Marathi'],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _appLanguage = val);
                      _updateSetting('app_language', val);
                    }
                  },
                ),
                _buildSettingsSlider(
                  icon: Icons.format_size,
                  title: 'font_size'.tr(context),
                  value: _fontSize,
                  onChanged: (val) => setState(() => _fontSize = val),
                  onChangeEnd: (val) => _updateSetting('font_size', val),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle('privacy_data'.tr(context)),
              _buildSettingsCard([
                _buildSettingsTile(
                  icon: Icons.history,
                  title: 'Clear Search History',
                  onTap: () {},
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle('support_feedback'.tr(context)),
              _buildSettingsCard([
                _buildSettingsTile(
                  icon: Icons.headset_mic_outlined,
                  title: 'contact_support'.tr(context),
                  onTap: () {},
                ),
                _buildSettingsTile(
                  icon: Icons.bug_report_outlined,
                  title: 'report_bug'.tr(context),
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
      ),
    );
  }

  Widget _buildProfileCard() {
    final user = _doctorData?['user'];
    final name = _doctorData?['full_name'] ?? 'doctor'.tr(context);
    final specialization = _doctorData?['specialization'] ?? 'specialist'.tr(context);
    final hospital = _doctorData?['hospital_name'] ?? 'healthcare_center'.tr(context);
    final photo = _doctorData?['profile_photo'];

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
              image: photo != null ? DecorationImage(image: NetworkImage(photo), fit: BoxFit.cover) : null,
            ),
            child: photo == null ? Icon(Icons.person, size: 40, color: primaryBlue) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. $name',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  specialization,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hospital,
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
      activeColor: primaryBlue,
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
          value: items.contains(value) ? value : items.first,
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
    required ValueChanged<double> onChangeEnd,
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
                  onChangeEnd: onChangeEnd,
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
          Provider.of<AuthProvider>(context, listen: false).logout();
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.roleSelection,
            (route) => false,
          );
        },
        icon: const Icon(Icons.logout, size: 20),
        label: Text(
          'logout'.tr(context),
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
