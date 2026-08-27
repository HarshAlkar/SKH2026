import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/permission_dialog_service.dart';
import '../../../core/services/settings_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_routes.dart';
import '../widgets/profile_avatar.dart';

class ProfileScreen extends StatefulWidget {
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  bool _saving = false;
  int _consultCount = 0;

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _village;
  late final TextEditingController _age;
  late final TextEditingController _gender;
  late final TextEditingController _blood;
  late final TextEditingController _address;
  late final TextEditingController _history;
  late final TextEditingController _specialization;
  late final TextEditingController _qualification;
  late final TextEditingController _experience;
  late final TextEditingController _hospital;
  late final TextEditingController _license;
  late final TextEditingController _bio;
  late final TextEditingController _workerId;
  late final TextEditingController _phc;
  late final TextEditingController _district;
  late final TextEditingController _assignedVillage;
  bool _available = true;

  String t(String en, String hi) => SettingsStore.instance.t(en, hi);

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _phone = TextEditingController();
    _email = TextEditingController();
    _village = TextEditingController();
    _age = TextEditingController();
    _gender = TextEditingController();
    _blood = TextEditingController();
    _address = TextEditingController();
    _history = TextEditingController();
    _specialization = TextEditingController();
    _qualification = TextEditingController();
    _experience = TextEditingController();
    _hospital = TextEditingController();
    _license = TextEditingController();
    _bio = TextEditingController();
    _workerId = TextEditingController();
    _phc = TextEditingController();
    _district = TextEditingController();
    _assignedVillage = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      _fillFromUser(auth.user);
      await auth.refreshUser();
      if (!mounted) return;
      _fillFromUser(auth.user);
      _loadConsults();
    });
  }

  Future<void> _loadConsults() async {
    try {
      final data = await ApiService().get('/consultations/history/');
      if (!mounted) return;
      setState(() => _consultCount = data is List ? data.length : 0);
    } catch (_) {}
  }

  void _fillFromUser(user) {
    if (user == null) return;
    _name.text = user.name;
    _phone.text = user.phoneNumber;
    _email.text = user.email;
    _village.text = user.village;
    _age.text = user.detail('age');
    _gender.text = user.detail('gender');
    _blood.text = user.detail('blood_group');
    _address.text = user.detail('address');
    _history.text = user.detail('medical_history');
    _specialization.text = user.detail('specialization');
    _qualification.text = user.detail('qualification');
    _experience.text = user.detail('experience_years');
    _hospital.text = user.detail('hospital_name');
    _license.text = user.detail('license_number');
    _bio.text = user.detail('bio');
    _workerId.text = user.detail('worker_id');
    _phc.text = user.detail('phc_center');
    _district.text = user.detail('district');
    _assignedVillage.text = user.detail('assigned_village', fallback: user.village);
    _available = user.profileDetails['is_available'] != false;
    setState(() {});
  }

  @override
  void dispose() {
    for (final c in [
      _name, _phone, _email, _village, _age, _gender, _blood, _address, _history,
      _specialization, _qualification, _experience, _hospital, _license, _bio,
      _workerId, _phc, _district, _assignedVillage,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(t('Take photo', 'फोटो लें')),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(t('Choose from gallery', 'गैलरी से चुनें')),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final permission = source == ImageSource.camera ? Permission.camera : Permission.photos;
    final allowed = await PermissionDialogService.ensure(
      context,
      permission: permission,
      title: t('Allow photos', 'फोटो की अनुमति दें'),
      message: t(
        'Allow camera or photos so you can set your profile picture.',
        'प्रोफ़ाइल फोटो सेट करने के लिए कैमरा या गैलरी की अनुमति दें।',
      ),
    );
    if (!allowed || !mounted) return;
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 1200);
    if (picked == null || !mounted) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.uploadPhoto(File(picked.path));
    if (!mounted) return;
    final pending = auth.user?.pendingPhotoPath?.isNotEmpty == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (pending
                  ? t(
                      'Photo saved on phone. Will upload when internet is back.',
                      'फोटो फ़ोन में सहेजी गई। इंटरनेट आने पर अपलोड होगी।',
                    )
                  : t('Photo updated', 'फोटो अपडेट हो गई'))
              : (auth.error ?? t('Could not update photo', 'फोटो अपडेट नहीं हुई')),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    final role = auth.user?.role ?? 'user';
    final details = <String, dynamic>{};
    if (role == 'user') {
      details.addAll({
        'age': int.tryParse(_age.text.trim()) ?? 0,
        'gender': _gender.text.trim(),
        'blood_group': _blood.text.trim(),
        'address': _address.text.trim(),
        'medical_history': _history.text.trim(),
      });
    } else if (role == 'doctor') {
      details.addAll({
        'specialization': _specialization.text.trim(),
        'qualification': _qualification.text.trim(),
        'experience_years': int.tryParse(_experience.text.trim()) ?? 0,
        'hospital_name': _hospital.text.trim(),
        'license_number': _license.text.trim(),
        'bio': _bio.text.trim(),
        'is_available': _available,
      });
    } else if (role == 'asha_worker') {
      details.addAll({
        'worker_id': _workerId.text.trim(),
        'phc_center': _phc.text.trim(),
        'district': _district.text.trim(),
        'assigned_village': _assignedVillage.text.trim(),
      });
    }

    setState(() => _saving = true);
    final ok = await auth.updateProfile({
      'name': _name.text.trim(),
      'phone_number': _phone.text.trim(),
      'email': _email.text.trim(),
      'village': role == 'asha_worker' ? _assignedVillage.text.trim() : _village.text.trim(),
      'profile_details': details,
    });
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) _editing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? t('Profile saved', 'प्रोफ़ाइल सेव हो गई') : (auth.error ?? t('Could not save', 'सेव नहीं हो सकी'))),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final role = user?.role ?? 'user';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: !widget.embedded,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          t('Profile', 'प्रोफ़ाइल'),
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _saving
                ? null
                : () {
                    if (_editing) {
                      _save();
                    } else {
                      setState(() => _editing = true);
                    }
                  },
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_editing ? t('Save', 'सेव') : t('Edit', 'संपादित')),
          ),
        ],
      ),
      body: user == null
          ? Center(child: Text(t('Please log in', 'कृपया लॉग इन करें')))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                Center(
                  child: ProfileAvatar(
                    user: user,
                    radius: 56,
                    backgroundColor: AppColors.lightBlue,
                    iconColor: AppColors.primary,
                    onTap: _pickPhoto,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    user.name.isEmpty ? t('Your name', 'आपका नाम') : user.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _roleLabel(role),
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _section(t('Account', 'खाता')),
                _field(_name, t('Full name', 'पूरा नाम'), Icons.person_outline),
                _field(_phone, t('Phone', 'फ़ोन'), Icons.phone_outlined, keyboard: TextInputType.phone),
                _field(_email, t('Email', 'ईमेल'), Icons.email_outlined, keyboard: TextInputType.emailAddress),
                if (role != 'asha_worker')
                  _field(_village, t('Village', 'गाँव'), Icons.location_on_outlined),
                if (role == 'user') ...[
                  const SizedBox(height: 8),
                  _section(t('Health details', 'स्वास्थ्य विवरण')),
                  _field(_age, t('Age', 'उम्र'), Icons.cake_outlined, keyboard: TextInputType.number),
                  _field(_gender, t('Gender', 'लिंग'), Icons.wc_outlined),
                  _field(_blood, t('Blood group', 'रक्त समूह'), Icons.bloodtype_outlined),
                  _field(_address, t('Address', 'पता'), Icons.home_outlined, maxLines: 2),
                  _field(_history, t('Medical history', 'चिकित्सा इतिहास'), Icons.note_alt_outlined, maxLines: 4),
                ],
                if (role == 'doctor') ...[
                  const SizedBox(height: 8),
                  _section(t('Professional', 'पेशेवर जानकारी')),
                  _field(_specialization, t('Specialization', 'विशेषज्ञता'), Icons.medical_services_outlined),
                  _field(_qualification, t('Qualification', 'योग्यता'), Icons.school_outlined),
                  _field(_experience, t('Experience (years)', 'अनुभव (वर्ष)'), Icons.timelapse, keyboard: TextInputType.number),
                  _field(_hospital, t('Hospital / clinic', 'अस्पताल / क्लिनिक'), Icons.local_hospital_outlined),
                  _field(_license, t('License number', 'लाइसेंस नंबर'), Icons.badge_outlined),
                  _field(_bio, t('Bio', 'परिचय'), Icons.info_outline, maxLines: 4),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t('Available for consultations', 'परामर्श के लिए उपलब्ध')),
                    value: _available,
                    onChanged: _editing ? (v) => setState(() => _available = v) : null,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history, color: AppColors.primary),
                    title: Text(t('Consultations', 'परामर्श')),
                    subtitle: Text('$_consultCount'),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.callHistory),
                  ),
                ],
                if (role == 'asha_worker') ...[
                  const SizedBox(height: 8),
                  _section(t('ASHA details', 'आशा विवरण')),
                  _field(_workerId, t('Worker ID', 'वर्कर आईडी'), Icons.badge_outlined),
                  _field(_phc, t('PHC center', 'पीएचसी केंद्र'), Icons.local_hospital_outlined),
                  _field(_district, t('District', 'जिला'), Icons.map_outlined),
                  _field(_assignedVillage, t('Assigned village', 'नियुक्त गाँव'), Icons.location_on_outlined),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
                  icon: const Icon(Icons.settings_outlined),
                  label: Text(t('Open settings', 'सेटिंग्स खोलें')),
                ),
              ],
            ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'doctor':
        return t('Doctor', 'डॉक्टर');
      case 'asha_worker':
        return t('ASHA Worker', 'आशा कार्यकर्ता');
      default:
        return t('Patient', 'मरीज');
    }
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enabled: _editing,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
