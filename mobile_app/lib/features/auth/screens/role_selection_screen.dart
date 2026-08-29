import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/server_host_helper.dart';
import '../../../core/services/locale_controller.dart';
import '../../../l10n/l10n.dart';
import '../../../routes/app_routes.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  int _hoveredIndex = -1;
  late final TextEditingController _hostController;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(text: AppConfig.host);
  }

  @override
  void dispose() {
    _hostController.dispose();
    super.dispose();
  }

  Future<void> _saveHost() async {
    final value = _hostController.text.trim();
    if (value.isEmpty) return;
    // Signaling always follows the API host (LAN :5000 or cloud signaling URL).
    await AppConfig.clearSignalingUrl();
    if (!mounted) return;
    await ServerHostHelper.saveHost(context, value);
    if (!mounted) return;
    setState(() {});
  }

  Widget _buildServerHostField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.serverCloudOrPc,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.activeApi(AppConfig.baseUrl),
            style: const TextStyle(fontSize: 11, color: AppColors.primary),
          ),
          const SizedBox(height: 2),
          Text(
            context.l10n.callsAuto(AppConfig.signalingServerUrl),
            style: const TextStyle(fontSize: 11, color: Color(0xFF0F766E)),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.serverHint,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _hostController,
                  decoration: InputDecoration(
                    hintText: '10.0.2.2 or https://…',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saveHost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(72, 44),
                ),
                child: Text(context.l10n.save),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              'assets/images/VitalReach_logo.png',
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.health_and_safety,
                  color: AppColors.primary,
                  size: 20,
                );
              },
            ),
          ),
        ),
        title: Text(
          context.l10n.appName,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Image.asset(
                  'assets/images/VitalReach_logo.png',
                  height: 180,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.selectRole,
                style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(context.l10n.english),
                    selected: LocaleController.instance.languageCode == 'en',
                    onSelected: (_) => LocaleController.instance.setLanguage('en'),
                  ),
                  ChoiceChip(
                    label: Text(context.l10n.hindi),
                    selected: LocaleController.instance.languageCode == 'hi',
                    onSelected: (_) => LocaleController.instance.setLanguage('hi'),
                  ),
                  ChoiceChip(
                    label: Text(context.l10n.marathi),
                    selected: LocaleController.instance.languageCode == 'mr',
                    onSelected: (_) => LocaleController.instance.setLanguage('mr'),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              _buildServerHostField(),

              _buildRoleCard(
                index: 0,
                icon: Icons.person_outline,
                title: context.l10n.rolePatient,
                description: context.l10n.rolePatientDesc,
                buttonText: context.l10n.continueAsPatient,
                color: AppColors.primary,
                onTap: () => Navigator.pushNamed(context, AppRoutes.userLogin),
              ),

              _buildRoleCard(
                index: 1,
                icon: Icons.assignment_ind_outlined,
                title: context.l10n.roleAsha,
                description: context.l10n.roleAshaDesc,
                buttonText: context.l10n.continueAsAsha,
                color: AppColors.secondary,
                onTap: () => Navigator.pushNamed(context, AppRoutes.ashaLogin),
              ),

              _buildRoleCard(
                index: 2,
                icon: Icons.medical_services_outlined,
                title: context.l10n.roleDoctor,
                description: context.l10n.roleDoctorDesc,
                buttonText: context.l10n.continueAsDoctor,
                color: Colors.orange,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.doctorLogin),
              ),

              const SizedBox(height: 20),
              Center(
                child: Text(
                  context.l10n.copyright,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required int index,
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required Color color,
    required VoidCallback onTap,
  }) {
    bool isHovered = _hoveredIndex == index;

    return GestureDetector(
      onTapDown: (_) => setState(() => _hoveredIndex = index),
      onTapUp: (_) => setState(() => _hoveredIndex = -1),
      onTapCancel: () => setState(() => _hoveredIndex = -1),
      child: AnimatedScale(
        scale: isHovered ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
