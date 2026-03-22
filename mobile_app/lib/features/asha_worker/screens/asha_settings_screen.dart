import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hs053/core/routes/app_routes.dart';
import 'package:hs053/shared/providers/auth_provider.dart';
import 'package:hs053/core/widgets/common_appbar.dart';
import '../widgets/asha_drawer.dart';

class AshaSettingsScreen extends StatefulWidget {
  const AshaSettingsScreen({super.key});

  @override
  State<AshaSettingsScreen> createState() => _AshaSettingsScreenState();
}

class _AshaSettingsScreenState extends State<AshaSettingsScreen> {
  // Toggle states
  bool _offlineSync = true;
  bool _biometricLogin = false;
  bool _notificationsEnabled = true;

  // Constants
  final Color primaryColor = const Color(0xFF2A7DE1);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const CommonAppBar(title: "Settings"),
      drawer: const AshaDrawer(currentRoute: AppRoutes.ashaSettings),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
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
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: primaryColor.withOpacity(0.1),
                      child: Icon(Icons.person, size: 40, color: primaryColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? "Sunita Ahirwar",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "ASHA Worker ID: ASH-2024-582",
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Village: Rampur",
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit_outlined, color: Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle("APP SETTINGS"),
              _buildSettingsCard([
                _buildToggleTile(
                  icon: Icons.sync,
                  title: "Offline Data Syncing",
                  subtitle: "Sync records when network is available",
                  value: _offlineSync,
                  onChanged: (val) => setState(() => _offlineSync = val),
                ),
                _buildToggleTile(
                  icon: Icons.fingerprint,
                  title: "Biometric Login",
                  subtitle: "Use fingerprint to secure the app",
                  value: _biometricLogin,
                  onChanged: (val) => setState(() => _biometricLogin = val),
                ),
                _buildToggleTile(
                  icon: Icons.notifications_none,
                  title: "Push Notifications",
                  subtitle: "Receive alerts about patient risks",
                  value: _notificationsEnabled,
                  onChanged: (val) => setState(() => _notificationsEnabled = val),
                ),
              ]),

              const SizedBox(height: 24),
              _buildSectionTitle("ACCOUNT"),
              _buildSettingsCard([
                _buildActionTile(
                  icon: Icons.language,
                  title: "App Language",
                  trailing: "English",
                  onTap: () {},
                ),
                _buildActionTile(
                  icon: Icons.storage_outlined,
                  title: "Local Database Storage",
                  trailing: "128 MB",
                  onTap: () {},
                ),
                _buildActionTile(
                  icon: Icons.help_outline,
                  title: "Support & FAQs",
                  onTap: () {},
                ),
              ]),

              const SizedBox(height: 32),
              
              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await authProvider.logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.roleSelection,
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: primaryColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: primaryColor,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.grey[700], size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(trailing, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
