import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_routes.dart';
import '../services/profile_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/profile_model.dart';
import '../../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();

  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  List<FamilyMemberModel> _familyMembers = [];
  EmergencyInfoModel? _emergencyInfo;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final profile = await _profileService.getUserProfile();
      final family = await _profileService.getFamilyMembers();
      EmergencyInfoModel? emergency;
      try {
        final e = await _profileService.getEmergencyInfo();
        emergency = EmergencyInfoModel.fromJson(e);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _profileData = profile;
          _familyMembers = family
              .map((m) => FamilyMemberModel.fromJson(m))
              .toList();
          _emergencyInfo = emergency;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception:', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Profile'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded, color: AppColors.primary),
            tooltip: 'My QR Code',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.qrCode),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: () => _handleLogout(authProvider),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildProfileHeader(user),
                    if (_error != null) _buildErrorBanner(),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoSection(user),
                          const SizedBox(height: 24),
                          _buildFamilySection(),
                          const SizedBox(height: 24),
                          _buildEmergencySection(),
                          const SizedBox(height: 24),
                          _buildQuickLinks(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ─────────────────── Profile Header ───────────────────

  Widget _buildProfileHeader(dynamic user) {
    final primary = AppColors.primary;
    final name = user.name ?? 'User';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: primary.withOpacity(0.12),
                child: Text(
                  initials,
                  style: TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: primary),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                child: const Icon(Icons.edit, color: Colors.white, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(user.village ?? 'Village not set', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          _buildAbhaChip(user),
        ],
      ),
    );
  }

  Widget _buildAbhaChip(UserModel user) {
    final abhaId = user.abhaId ?? 'Not linked';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTap: () {
            if (user.abhaId != null) {
              Clipboard.setData(ClipboardData(text: user.abhaId!));
              Helpers.showSnackBar(context, 'ABHA ID copied to clipboard');
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF4A90E2)]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('ABHA: $abhaId', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                const Icon(Icons.copy_rounded, color: Colors.white70, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.qrCode),
          icon: const Icon(Icons.qr_code_2_rounded, color: AppColors.primary),
          tooltip: 'Show QR Code',
        ),
      ],
    );
  }

  // ─────────────────── Error Banner ───────────────────

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing cached data. $_error',
              style: const TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────── Info Section ───────────────────

  Widget _buildInfoSection(dynamic user) {
    return _buildCard(
      title: 'Personal Information',
      icon: Icons.person_outline,
      child: Column(
        children: [
          _infoTile(Icons.phone_outlined, 'Phone', user.phoneNumber ?? 'Not set'),
          _infoTile(Icons.email_outlined, 'Email', user.email ?? 'Not set'),
          _infoTile(Icons.location_on_outlined, 'Village', user.village ?? 'Not set'),
          if (_profileData?['profile_details'] != null) ...[
            _infoTile(Icons.bloodtype_outlined, 'Blood Group', _profileData!['profile_details']['blood_group'] ?? 'Not set'),
            _infoTile(Icons.cake_outlined, 'Age', _profileData!['profile_details']['age']?.toString() ?? 'Not set'),
            _infoTile(Icons.wc_outlined, 'Gender', _profileData!['profile_details']['gender'] ?? 'Not set'),
          ],
        ],
      ),
    );
  }

  // ─────────────────── Family Section ───────────────────

  Widget _buildFamilySection() {
    return _buildCard(
      title: 'Family Members',
      icon: Icons.people_outline,
      trailing: TextButton.icon(
        onPressed: _showAddFamilyMemberDialog,
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add'),
      ),
      child: _familyMembers.isEmpty
          ? _emptyState('No family members added yet.', Icons.family_restroom_outlined)
          : Column(
              children: _familyMembers
                  .map((m) => _familyMemberTile(m))
                  .toList(),
            ),
    );
  }

  Widget _familyMemberTile(FamilyMemberModel m) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: Text(m.name[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
      ),
      title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${m.relationship} · ${m.phoneNumber}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
        onPressed: () => _deleteFamilyMember(m),
      ),
    );
  }

  void _showAddFamilyMemberDialog() {
    final nameCtrl = TextEditingController();
    final relationCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Family Member', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _inputField(nameCtrl, 'Name', Icons.person_outline),
            const SizedBox(height: 12),
            _inputField(relationCtrl, 'Relation (e.g. Sister)', Icons.people_outline),
            const SizedBox(height: 12),
            _inputField(ageCtrl, 'Age', Icons.cake_outlined, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _inputField(phoneCtrl, 'Phone Number', Icons.phone_outlined, keyboardType: TextInputType.phone),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty || relationCtrl.text.isEmpty) {
                    Helpers.showSnackBar(context, 'Name and relation are required', isError: true);
                    return;
                  }
                  Navigator.pop(ctx);
                  await _addFamilyMember(FamilyMemberModel(
                    name: nameCtrl.text.trim(),
                    relationship: relationCtrl.text.trim(),
                    age: int.tryParse(ageCtrl.text) ?? 0,
                    phoneNumber: phoneCtrl.text.trim(),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Add Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addFamilyMember(FamilyMemberModel member) async {
    try {
      await _profileService.addFamilyMember(member.toJson());
      if (mounted) {
        Helpers.showSnackBar(context, 'Family member added');
        _loadAll();
      }
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, e.toString(), isError: true);
    }
  }

  Future<void> _deleteFamilyMember(FamilyMemberModel member) async {
    if (member.id == null) return;
    try {
      await _profileService.deleteFamilyMember(member.id!);
      if (mounted) {
        Helpers.showSnackBar(context, 'Member removed');
        _loadAll();
      }
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, e.toString(), isError: true);
    }
  }

  // ─────────────────── Emergency Section ───────────────────

  Widget _buildEmergencySection() {
    return _buildCard(
      title: 'Emergency Info',
      icon: Icons.emergency_outlined,
      iconColor: Colors.red,
      trailing: TextButton.icon(
        onPressed: _showEmergencyEditDialog,
        icon: const Icon(Icons.edit, size: 16),
        label: Text(_emergencyInfo == null ? 'Add' : 'Edit'),
      ),
      child: _emergencyInfo == null
          ? _emptyState('No emergency info added yet.\nAdd blood group and emergency contacts.', Icons.health_and_safety_outlined)
          : Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.15)),
              ),
              child: Column(
                children: [
                  _infoTile(Icons.bloodtype_outlined, 'Blood Group', _emergencyInfo!.bloodGroup.isEmpty ? 'Not set' : _emergencyInfo!.bloodGroup),
                  _infoTile(Icons.person_outline, 'Emergency Contact', _emergencyInfo!.contactName.isEmpty ? 'Not set' : '${_emergencyInfo!.contactName} (${_emergencyInfo!.relationship})'),
                  _infoTile(Icons.phone_outlined, 'Contact Phone', _emergencyInfo!.phoneNumber.isEmpty ? 'Not set' : _emergencyInfo!.phoneNumber),
                  if (_emergencyInfo!.medicalNotes.isNotEmpty)
                    _infoTile(Icons.note_outlined, 'Medical Notes', _emergencyInfo!.medicalNotes),
                  if (_emergencyInfo!.allergies.isNotEmpty)
                    _infoTile(Icons.warning_outlined, 'Allergies', _emergencyInfo!.allergies),
                ],
              ),
            ),
    );
  }

  void _showEmergencyEditDialog() {
    final nameCtrl = TextEditingController(text: _emergencyInfo?.contactName ?? '');
    final relCtrl = TextEditingController(text: _emergencyInfo?.relationship ?? '');
    final phoneCtrl = TextEditingController(text: _emergencyInfo?.phoneNumber ?? '');
    final bgCtrl = TextEditingController(text: _emergencyInfo?.bloodGroup ?? '');
    final notesCtrl = TextEditingController(text: _emergencyInfo?.medicalNotes ?? '');
    final allergyCtrl = TextEditingController(text: _emergencyInfo?.allergies ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.emergency_outlined, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Emergency Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              _inputField(bgCtrl, 'Blood Group (e.g. O+)', Icons.bloodtype_outlined),
              const SizedBox(height: 12),
              _inputField(nameCtrl, 'Emergency Contact Name', Icons.person_outline),
              const SizedBox(height: 12),
              _inputField(relCtrl, 'Relation', Icons.people_outline),
              const SizedBox(height: 12),
              _inputField(phoneCtrl, 'Contact Phone', Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _inputField(notesCtrl, 'Medical Notes', Icons.note_outlined, maxLines: 2),
              const SizedBox(height: 12),
              _inputField(allergyCtrl, 'Allergies', Icons.warning_outlined),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _saveEmergencyInfo({
                      'contact_name': nameCtrl.text.trim(),
                      'relationship': relCtrl.text.trim(),
                      'phone_number': phoneCtrl.text.trim(),
                      'blood_group': bgCtrl.text.trim(),
                      'medical_notes': notesCtrl.text.trim(),
                      'allergies': allergyCtrl.text.trim(),
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Emergency Info', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveEmergencyInfo(Map<String, dynamic> data) async {
    try {
      await _profileService.updateEmergencyInfo(data);
      if (mounted) {
        Helpers.showSnackBar(context, 'Emergency info saved');
        _loadAll();
      }
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, e.toString(), isError: true);
    }
  }

  // ─────────────────── Quick Links ───────────────────

  Widget _buildQuickLinks() {
    return _buildCard(
      title: 'Health Records',
      icon: Icons.folder_outlined,
      child: Column(
        children: [
          _menuTile(Icons.description_outlined, 'Reports & Documents', () => Navigator.pushNamed(context, AppRoutes.reports)),
          _menuTile(Icons.medication_outlined, 'My Prescriptions', () => Navigator.pushNamed(context, AppRoutes.myPrescriptions)),
          _menuTile(Icons.qr_code_rounded, 'My QR Code', () => Navigator.pushNamed(context, AppRoutes.qrCode)),
          _menuTile(Icons.qr_code_scanner, 'Scan a QR', () => Navigator.pushNamed(context, AppRoutes.qrScanner)),
        ],
      ),
    );
  }

  // ─────────────────── Helpers / Widgets ───────────────────

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
    Color? iconColor,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menuTile(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500))),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(text, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  void _handleLogout(AuthProvider auth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await auth.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.roleSelection, (_) => false);
      }
    }
  }
}
