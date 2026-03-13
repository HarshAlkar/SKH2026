import 'package:flutter/material.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_section.dart';
import '../../asha_worker/widgets/asha_drawer.dart';
import '../../../routes/app_routes.dart';
import './edit_profile_screen.dart';
import './change_password_screen.dart';
import './update_phone_screen.dart';
import './help_center_screen.dart';
import './contact_support_screen.dart';
import './report_issue_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _pinLockEnabled = true;
  String _selectedLanguage = 'English';

  final Color primaryColor = const Color(0xFF2F4DB6);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.ashaLogin, (route) => false);
            },
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Clear cached data?"),
        content: const Text(
          "This will remove temporary files but keep your records safe.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Cache cleared successfully."),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              "Clear",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
      ),
      drawer: const AshaDrawer(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // PROFILE CARD
            Container(
              margin: const EdgeInsets.all(16),
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
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor.withOpacity(0.1),
                        ),
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Sunita Sharma",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Worker ID: AW-208154",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _navigateTo(const EditProfileScreen()),
                        icon: Icon(
                          Icons.edit_note_rounded,
                          color: primaryColor,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 40, thickness: 1),
                  Row(
                    children: [
                      _buildProfileInfoItem(
                        Icons.map_outlined,
                        "District:",
                        "Pune",
                      ),
                      const Spacer(),
                      _buildProfileInfoItem(
                        Icons.location_city_outlined,
                        "Village:",
                        "Rampur",
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ACCOUNT SETTINGS
            SettingsSection(
              title: "ACCOUNT SETTINGS",
              children: [
                SettingsTile(
                  icon: Icons.person_outline,
                  title: "Edit Profile",
                  onTap: () => _navigateTo(const EditProfileScreen()),
                ),
                SettingsTile(
                  icon: Icons.lock_outline,
                  title: "Change Password",
                  onTap: () => _navigateTo(const ChangePasswordScreen()),
                ),
                SettingsTile(
                  icon: Icons.phone_outlined,
                  title: "Update Phone Number",
                  onTap: () => _navigateTo(const UpdatePhoneScreen()),
                ),
              ],
            ),

            // APP PREFERENCES
            SettingsSection(
              title: "APP PREFERENCES",
              children: [
                SettingsTile(
                  icon: Icons.language_outlined,
                  title: "Language Selection",
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLanguage,
                      items: ['English', 'Hindi', 'Marathi']
                          .map(
                            (lang) => DropdownMenuItem(
                              value: lang,
                              child: Text(
                                lang,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null)
                          setState(() => _selectedLanguage = val);
                      },
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
                SettingsTile(
                  icon: Icons.notifications_none_outlined,
                  title: "Notifications",
                  subtitle: "Enable or disable health alerts",
                  trailing: Switch(
                    value: _notificationsEnabled,
                    activeColor: const Color(0xFF2F4DB6),
                    onChanged: (val) =>
                        setState(() => _notificationsEnabled = val),
                  ),
                ),
                SettingsTile(
                  icon: Icons.sync_outlined,
                  title: "Offline Sync Status",
                  subtitle: "3 records pending sync",
                  trailing: const Text(
                    "Enabled",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            // SECURITY
            SettingsSection(
              title: "SECURITY",
              children: [
                SettingsTile(
                  icon: Icons.fingerprint_outlined,
                  title: "Enable Biometric Login",
                  trailing: Switch(
                    value: _biometricEnabled,
                    activeColor: const Color(0xFF2F4DB6),
                    onChanged: (val) => setState(() => _biometricEnabled = val),
                  ),
                ),
                SettingsTile(
                  icon: Icons.pin_outlined,
                  title: "Enable PIN Lock",
                  trailing: Switch(
                    value: _pinLockEnabled,
                    activeColor: const Color(0xFF2F4DB6),
                    onChanged: (val) => setState(() => _pinLockEnabled = val),
                  ),
                ),
                SettingsTile(
                  icon: Icons.delete_outline,
                  title: "Clear App Cache",
                  onTap: _showClearCacheDialog,
                ),
              ],
            ),

            // HELP & SUPPORT
            SettingsSection(
              title: "HELP & SUPPORT",
              children: [
                SettingsTile(
                  icon: Icons.help_outline,
                  title: "Help Center",
                  onTap: () => _navigateTo(const HelpCenterScreen()),
                ),
                SettingsTile(
                  icon: Icons.contact_support_outlined,
                  title: "Contact Support",
                  onTap: () => _navigateTo(const ContactSupportScreen()),
                ),
                SettingsTile(
                  icon: Icons.bug_report_outlined,
                  title: "Report Issue",
                  onTap: () => _navigateTo(const ReportIssueScreen()),
                ),
              ],
            ),

            // APP INFORMATION
            SettingsSection(
              title: "APP INFORMATION",
              children: [
                const SettingsTile(
                  icon: Icons.info_outline,
                  title: "App Version",
                  trailing: Text(
                    "v1.0.0",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ],
            ),

            // LOGOUT BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: InkWell(
                  onTap: _showLogoutDialog,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.logout, color: Colors.red, size: 20),
                        const SizedBox(width: 12),
                        const Text(
                          "Logout Account",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
