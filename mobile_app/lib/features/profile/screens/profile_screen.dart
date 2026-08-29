import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/permission_dialog_service.dart';
import '../../../core/services/settings_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/emergency_contact_model.dart';
import '../../../models/user_model.dart';
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
  int _consultCount = 0;

  // Section-based editing states
  bool _editingAccount = false;
  bool _savingAccount = false;

  bool _editingHealth = false;
  bool _savingHealth = false;

  bool _editingDoctor = false;
  bool _savingDoctor = false;

  bool _editingAsha = false;
  bool _savingAsha = false;

  // Emergency Contacts state
  List<EmergencyContactModel> _emergencyContacts = [];
  bool _loadingContacts = false;

  // Controllers
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
      if (auth.user?.role == 'user') {
        _loadContacts();
      }
    });
  }

  Future<void> _loadConsults() async {
    try {
      final data = await ApiService().get('/consultations/history/');
      if (!mounted) return;
      setState(() => _consultCount = data is List ? data.length : 0);
    } catch (_) {}
  }

  Future<void> _loadContacts() async {
    setState(() => _loadingContacts = true);
    try {
      final res = await ApiService().get('/patients/emergency-contacts/');
      if (res is List) {
        _emergencyContacts = res
            .whereType<Map>()
            .map((m) => EmergencyContactModel.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _loadingContacts = false);
    }
  }

  void _fillFromUser(UserModel? user) {
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

    if (user.emergencyContacts.isNotEmpty) {
      _emergencyContacts = List.from(user.emergencyContacts);
    }

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
      _name,
      _phone,
      _email,
      _village,
      _age,
      _gender,
      _blood,
      _address,
      _history,
      _specialization,
      _qualification,
      _experience,
      _hospital,
      _license,
      _bio,
      _workerId,
      _phc,
      _district,
      _assignedVillage,
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

  Future<void> _saveAccount() async {
    final auth = context.read<AuthProvider>();
    setState(() => _savingAccount = true);
    final ok = await auth.updateProfile({
      'name': _name.text.trim(),
      'phone_number': _phone.text.trim(),
      'email': _email.text.trim(),
      'village': _village.text.trim(),
    });
    if (!mounted) return;
    setState(() {
      _savingAccount = false;
      if (ok) _editingAccount = false;
    });
    if (ok) {
      _fillFromUser(auth.user);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? t('Account saved', 'खाता विवरण सेव हो गया') : (auth.error ?? t('Could not save', 'सेव नहीं हो सकी'))),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _saveHealth() async {
    final auth = context.read<AuthProvider>();
    setState(() => _savingHealth = true);
    final ok = await auth.updateProfile({
      'profile_details': {
        'age': int.tryParse(_age.text.trim()) ?? 0,
        'gender': _gender.text.trim(),
        'blood_group': _blood.text.trim(),
        'address': _address.text.trim(),
        'medical_history': _history.text.trim(),
      },
    });
    if (!mounted) return;
    setState(() {
      _savingHealth = false;
      if (ok) _editingHealth = false;
    });
    if (ok) {
      _fillFromUser(auth.user);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? t('Health details saved', 'स्वास्थ्य विवरण सेव हो गया') : (auth.error ?? t('Could not save', 'सेव नहीं हो सकी'))),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _saveDoctor() async {
    final auth = context.read<AuthProvider>();
    setState(() => _savingDoctor = true);
    final ok = await auth.updateProfile({
      'profile_details': {
        'specialization': _specialization.text.trim(),
        'qualification': _qualification.text.trim(),
        'experience_years': int.tryParse(_experience.text.trim()) ?? 0,
        'hospital_name': _hospital.text.trim(),
        'license_number': _license.text.trim(),
        'bio': _bio.text.trim(),
        'is_available': _available,
      },
    });
    if (!mounted) return;
    setState(() {
      _savingDoctor = false;
      if (ok) _editingDoctor = false;
    });
    if (ok) {
      _fillFromUser(auth.user);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? t('Doctor details saved', 'डॉक्टर विवरण सेव हो गया') : (auth.error ?? t('Could not save', 'सेव नहीं हो सकी'))),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _saveAsha() async {
    final auth = context.read<AuthProvider>();
    setState(() => _savingAsha = true);
    final ok = await auth.updateProfile({
      'village': _assignedVillage.text.trim(),
      'profile_details': {
        'worker_id': _workerId.text.trim(),
        'phc_center': _phc.text.trim(),
        'district': _district.text.trim(),
        'assigned_village': _assignedVillage.text.trim(),
      },
    });
    if (!mounted) return;
    setState(() {
      _savingAsha = false;
      if (ok) _editingAsha = false;
    });
    if (ok) {
      _fillFromUser(auth.user);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? t('ASHA details saved', 'आशा विवरण सेव हो गया') : (auth.error ?? t('Could not save', 'सेव नहीं हो सकी'))),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  void _showAddEditContactDialog({EmergencyContactModel? contact}) {
    final nameCtrl = TextEditingController(text: contact?.name ?? '');
    final phoneCtrl = TextEditingController(text: contact?.phone ?? '');
    String relationship = contact?.relationship ?? 'Brother';
    final relationships = ['Father', 'Mother', 'Brother', 'Sister', 'Spouse', 'Son', 'Daughter', 'Friend', 'Other'];
    if (!relationships.contains(relationship)) {
      relationship = 'Other';
    }

    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            contact == null ? t('Add Emergency Contact', 'आपातकालीन संपर्क जोड़ें') : t('Edit Emergency Contact', 'आपातकालीन संपर्क संपादित करें'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15),
                  decoration: InputDecoration(
                    labelText: t('Contact person name', 'संपर्क व्यक्ति का नाम'),
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15),
                  decoration: InputDecoration(
                    labelText: t('Emergency phone number', 'आपातकालीन फ़ोन नंबर'),
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: relationship,
                  items: relationships
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => relationship = v);
                  },
                  decoration: InputDecoration(
                    labelText: t('Relationship', 'संबंध'),
                    prefixIcon: const Icon(Icons.people_outline, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
              child: Text(t('Cancel', 'रद्द करें'), style: const TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final phone = phoneCtrl.text.trim();
                      if (name.isEmpty || phone.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(t('Please enter both name and phone', 'कृपया नाम और फ़ोन दोनों दर्ज करें'))),
                        );
                        return;
                      }
                      setDialogState(() => isSubmitting = true);
                      try {
                        if (contact == null) {
                          await ApiService().post('/patients/emergency-contacts/', body: {
                            'name': name,
                            'phone': phone,
                            'relationship': relationship,
                          });
                        } else {
                          await ApiService().patch('/patients/emergency-contacts/${contact.id}/', body: {
                            'name': name,
                            'phone': phone,
                            'relationship': relationship,
                          });
                        }
                        if (mounted) {
                          await context.read<AuthProvider>().refreshUser();
                          await _loadContacts();
                          Navigator.pop(dialogCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(t('Emergency contact saved', 'आपातकालीन संपर्क सहेजा गया')),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(t('Save', 'सेव')),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(EmergencyContactModel contact) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t('Remove Emergency Contact', 'आपातकालीन संपर्क हटाएं'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Text(
          t(
            'Are you sure you want to remove ${contact.name} from your emergency contacts?',
            'क्या आप निश्चित रूप से ${contact.name} को अपने आपातकालीन संपर्कों से हटाना चाहते हैं?',
          ),
          style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(t('Cancel', 'रद्द करें'), style: const TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              try {
                await ApiService().delete('/patients/emergency-contacts/${contact.id}/');
                if (mounted) {
                  await context.read<AuthProvider>().refreshUser();
                  await _loadContacts();
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t('Contact removed', 'संपर्क हटा दिया गया')),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(t('Remove', 'हटाएं')),
          ),
        ],
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
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
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
                if (role == 'doctor' || role == 'asha_worker') _buildVerificationSection(user, role),
                const SizedBox(height: 24),

                // 1. ACCOUNT SECTION
                _sectionHeader(
                  title: t('Account', 'खाता'),
                  isEditing: _editingAccount,
                  isSaving: _savingAccount,
                  onEdit: () => setState(() => _editingAccount = true),
                  onSave: _saveAccount,
                  onCancel: () {
                    _fillFromUser(auth.user);
                    setState(() => _editingAccount = false);
                  },
                ),
                _field(_name, t('Full name', 'पूरा नाम'), Icons.person_outline, isEditing: _editingAccount),
                _field(_phone, t('Phone', 'फ़ोन'), Icons.phone_outlined, keyboard: TextInputType.phone, isEditing: _editingAccount),
                _field(_email, t('Email', 'ईमेल'), Icons.email_outlined, keyboard: TextInputType.emailAddress, isEditing: _editingAccount),
                if (role != 'asha_worker')
                  _field(_village, t('Village', 'गाँव'), Icons.location_on_outlined, isEditing: _editingAccount),

                // 2. PATIENT SECTIONS
                if (role == 'user') ...[
                  const SizedBox(height: 16),
                  _sectionHeader(
                    title: t('Health details', 'स्वास्थ्य विवरण'),
                    isEditing: _editingHealth,
                    isSaving: _savingHealth,
                    onEdit: () => setState(() => _editingHealth = true),
                    onSave: _saveHealth,
                    onCancel: () {
                      _fillFromUser(auth.user);
                      setState(() => _editingHealth = false);
                    },
                  ),
                  _field(_age, t('Age', 'उम्र'), Icons.cake_outlined, keyboard: TextInputType.number, isEditing: _editingHealth),
                  _field(_gender, t('Gender', 'लिंग'), Icons.wc_outlined, isEditing: _editingHealth),
                  _field(_blood, t('Blood group', 'रक्त समूह'), Icons.bloodtype_outlined, isEditing: _editingHealth),
                  _field(_address, t('Address', 'पता'), Icons.home_outlined, maxLines: 2, isEditing: _editingHealth),
                  _field(_history, t('Medical history', 'चिकित्सा इतिहास'), Icons.note_alt_outlined, maxLines: 4, isEditing: _editingHealth),

                  const SizedBox(height: 20),
                  // EMERGENCY CONTACTS SECTION (Multiple contacts support)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10, top: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t('Emergency Contacts', 'आपातकालीन संपर्क').toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showAddEditContactDialog(),
                          icon: const Icon(Icons.add, size: 16),
                          label: Text(t('Add', 'जोड़ें')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_loadingContacts)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (_emergencyContacts.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Center(
                        child: Text(
                          t('No emergency contacts added yet. Tap "+ Add" to add one.', 'अभी तक कोई आपातकालीन संपर्क नहीं जोड़ा गया है। जोड़ने के लिए "+ जोड़ें" पर टैप करें।'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ..._emergencyContacts.map((contact) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.person_pin, color: AppColors.primary, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            contact.name,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF0F172A),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (contact.relationship.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEEF2F6),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              contact.relationship,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF475569),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      contact.phone,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                tooltip: t('Edit', 'संपादित करें'),
                                onPressed: () => _showAddEditContactDialog(contact: contact),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                tooltip: t('Delete', 'हटाएं'),
                                onPressed: () => _showDeleteConfirmDialog(contact),
                              ),
                            ],
                          ),
                        )),
                ],

                // 3. DOCTOR SECTIONS
                if (role == 'doctor') ...[
                  const SizedBox(height: 16),
                  _sectionHeader(
                    title: t('Professional details', 'पेशेवर जानकारी'),
                    isEditing: _editingDoctor,
                    isSaving: _savingDoctor,
                    onEdit: () => setState(() => _editingDoctor = true),
                    onSave: _saveDoctor,
                    onCancel: () {
                      _fillFromUser(auth.user);
                      setState(() => _editingDoctor = false);
                    },
                  ),
                  _field(_specialization, t('Specialization', 'विशेषज्ञता'), Icons.medical_services_outlined, isEditing: _editingDoctor),
                  _field(_qualification, t('Qualification', 'योग्यता'), Icons.school_outlined, isEditing: _editingDoctor),
                  _field(_experience, t('Experience (years)', 'अनुभव (वर्ष)'), Icons.timelapse, keyboard: TextInputType.number, isEditing: _editingDoctor),
                  _field(_hospital, t('Hospital / clinic', 'अस्पताल / क्लिनिक'), Icons.local_hospital_outlined, isEditing: _editingDoctor),
                  _field(_license, t('License number', 'लाइसेंस नंबर'), Icons.badge_outlined, isEditing: _editingDoctor),
                  _field(_bio, t('Bio', 'परिचय'), Icons.info_outline, maxLines: 4, isEditing: _editingDoctor),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t('Available for consultations', 'परामर्श के लिए उपलब्ध')),
                    value: _available,
                    onChanged: _editingDoctor ? (v) => setState(() => _available = v) : null,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history, color: AppColors.primary),
                    title: Text(t('Consultations', 'परामर्श')),
                    subtitle: Text('$_consultCount'),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.callHistory),
                  ),
                ],

                // 4. ASHA WORKER SECTIONS
                if (role == 'asha_worker') ...[
                  const SizedBox(height: 16),
                  _sectionHeader(
                    title: t('ASHA details', 'आशा विवरण'),
                    isEditing: _editingAsha,
                    isSaving: _savingAsha,
                    onEdit: () => setState(() => _editingAsha = true),
                    onSave: _saveAsha,
                    onCancel: () {
                      _fillFromUser(auth.user);
                      setState(() => _editingAsha = false);
                    },
                  ),
                  _field(_workerId, t('Worker ID', 'वर्कर आईडी'), Icons.badge_outlined, isEditing: _editingAsha),
                  _field(_phc, t('PHC center', 'पीएचसी केंद्र'), Icons.local_hospital_outlined, isEditing: _editingAsha),
                  _field(_district, t('District', 'जिला'), Icons.map_outlined, isEditing: _editingAsha),
                  _field(_assignedVillage, t('Assigned village', 'नियुक्त गाँव'), Icons.location_on_outlined, isEditing: _editingAsha),
                ],

                const SizedBox(height: 24),
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

  Widget _sectionHeader({
    required String title,
    required bool isEditing,
    required bool isSaving,
    required VoidCallback onEdit,
    required VoidCallback onSave,
    required VoidCallback onCancel,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          if (isSaving)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            )
          else if (isEditing)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: onCancel,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      t('Cancel', 'रद्द करें'),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    t('Save', 'सेव'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            )
          else
            InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      t('Edit', 'संपादित करें'),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    int maxLines = 1,
    required bool isEditing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        readOnly: !isEditing,
        keyboardType: keyboard,
        maxLines: maxLines,
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isEditing ? AppColors.primary : const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: isEditing ? AppColors.primary : const Color(0xFF94A3B8),
            size: 20,
          ),
          filled: true,
          fillColor: isEditing ? Colors.white : const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isEditing ? AppColors.primary.withOpacity(0.5) : const Color(0xFFE2E8F0),
              width: isEditing ? 1.2 : 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationSection(UserModel user, String role) {
    final status = user.getDetail('verification_status', fallback: 'INCOMPLETE');

    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'VERIFIED':
        color = Colors.green;
        text = t('VERIFIED', 'सत्यापित');
        icon = Icons.verified;
        break;
      case 'PENDING_VERIFICATION':
        color = Colors.orange;
        text = t('VERIFICATION PENDING', 'सत्यापन लंबित');
        icon = Icons.hourglass_empty;
        break;
      case 'REJECTED':
        color = Colors.red;
        text = t('VERIFICATION REJECTED', 'सत्यापन अस्वीकृत');
        icon = Icons.error_outline;
        break;
      case 'INCOMPLETE':
      default:
        color = Colors.red;
        text = t('UNVERIFIED', 'असत्यापित');
        icon = Icons.warning_amber_rounded;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          if (status == 'INCOMPLETE' || status == 'REJECTED')
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextButton.icon(
                onPressed: () {
                  if (role == 'asha_worker') {
                    Navigator.pushNamed(context, '/asha-verification');
                  } else {
                    Navigator.pushNamed(context, '/doctor-verification');
                  }
                },
                icon: const Icon(Icons.upload_file, size: 16),
                label: Text(t('Complete Your Profile', 'अपनी प्रोफ़ाइल पूरी करें')),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: AppColors.lightBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
