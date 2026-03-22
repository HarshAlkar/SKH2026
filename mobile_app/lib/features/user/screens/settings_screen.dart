import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hs053/core/theme/app_colors.dart';
import 'package:hs053/core/routes/app_routes.dart';
import 'package:hs053/shared/providers/auth_provider.dart';
import 'package:hs053/shared/providers/language_provider.dart';
import 'package:hs053/core/localization/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(lang?.translate('settings') ?? 'Settings', 
          style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(lang?.translate('profile') ?? 'Profile'),
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: lang?.translate('profile') ?? 'Profile Settings',
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(lang?.translate('language') ?? 'Language'),
          _buildSettingsTile(
            icon: Icons.language,
            title: lang?.translate('change_language') ?? 'Change Language',
            subtitle: _getLanguageName(languageProvider.appLocale.languageCode, lang),
            onTap: () => _showLanguageDialog(context, languageProvider, lang),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(lang?.translate('notifications') ?? 'Notifications'),
          SwitchListTile(
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.notifications_none, color: AppColors.primary),
            ),
            title: Text(lang?.translate('notifications') ?? 'Push Notifications',
              style: const TextStyle(fontWeight: FontWeight.w600)),
            value: _notificationsEnabled,
            activeColor: AppColors.primary,
            onChanged: (val) {
              setState(() => _notificationsEnabled = val);
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(lang?.translate('privacy_security') ?? 'Privacy & Security'),
          _buildSettingsTile(
            icon: Icons.lock_outline,
            title: lang?.translate('privacy_security') ?? 'Privacy Policy',
            onTap: () {
              // Navigation or action
            },
          ),
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () => _showLogoutDialog(context, lang),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.1),
                foregroundColor: Colors.redAccent,
                elevation: 0,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.redAccent),
                ),
              ),
              child: Text(lang?.translate('logout') ?? 'Logout', 
                style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  String _getLanguageName(String code, AppLocalizations? lang) {
    switch (code) {
      case 'hi': return lang?.translate('hindi') ?? 'Hindi';
      case 'mr': return lang?.translate('marathi') ?? 'Marathi';
      default: return lang?.translate('english') ?? 'English';
    }
  }

  void _showLanguageDialog(BuildContext context, LanguageProvider provider, AppLocalizations? lang) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(lang?.translate('select_language') ?? 'Select Language',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildLanguageOption(context, provider, 'en', lang?.translate('english') ?? 'English'),
              _buildLanguageOption(context, provider, 'hi', lang?.translate('hindi') ?? 'Hindi'),
              _buildLanguageOption(context, provider, 'mr', lang?.translate('marathi') ?? 'Marathi'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(BuildContext context, LanguageProvider provider, String code, String name) {
    final isSelected = provider.appLocale.languageCode == code;
    return ListTile(
      title: Text(name, style: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.primary : Colors.black87,
      )),
      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
      onTap: () {
        provider.changeLanguage(Locale(code));
        Navigator.pop(context);
      },
    );
  }

  void _showLogoutDialog(BuildContext context, AppLocalizations? lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang?.translate('logout') ?? 'Logout'),
        content: Text(lang?.translate('logout_confirm') ?? 'Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang?.translate('cancel') ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              await auth.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.roleSelection, (route) => false);
              }
            },
            child: Text(lang?.translate('yes') ?? 'Yes', style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
