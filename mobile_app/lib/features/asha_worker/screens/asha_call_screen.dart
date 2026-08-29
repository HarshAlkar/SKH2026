import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../chat/screens/chat_inbox_screen.dart';
import '../../chat/widgets/contact_action_row.dart';
import '../../chat/widgets/directory_contact_card.dart';

class AshaCallScreen extends StatefulWidget {
  final bool embedded;
  const AshaCallScreen({super.key, this.embedded = false});

  @override
  State<AshaCallScreen> createState() => _AshaCallScreenState();
}

class _AshaCallScreenState extends State<AshaCallScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late final TabController _tabs;
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _doctors = [];
  bool _loadingPatients = true;
  bool _loadingDoctors = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadPatients();
    _loadDoctors();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() => _loadingPatients = true);
    try {
      final data = await _api.get('/users/patients/');
      if (!mounted) return;
      setState(() {
        _patients = data is List
            ? List<Map<String, dynamic>>.from(data)
            : [];
        _loadingPatients = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingPatients = false);
    }
  }

  Future<void> _loadDoctors() async {
    setState(() => _loadingDoctors = true);
    try {
      final data = await _api.get('/doctors/');
      if (!mounted) return;
      setState(() {
        _doctors = data is List
            ? List<Map<String, dynamic>>.from(data)
            : [];
        _loadingDoctors = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingDoctors = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: !widget.embedded,
        title: const Text(
          'Call',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            tooltip: 'Messages',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatInboxScreen()),
              );
            },
            icon: const Icon(Icons.chat_outlined),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Patients'),
            Tab(text: 'Doctors'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildPatientsTab(),
          _buildDoctorsTab(),
        ],
      ),
    );
  }

  Widget _buildPatientsTab() {
    if (_loadingPatients) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _loadPatients,
      child: _patients.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text('No village patients found')),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _patients.length,
              itemBuilder: (context, index) {
                final patient = _patients[index];
                final details = patient['profile_details'] is Map
                    ? Map<String, dynamic>.from(patient['profile_details'] as Map)
                    : <String, dynamic>{};
                final peerId = parseContactId(patient['id']);
                if (peerId == null) return const SizedBox.shrink();
                return DirectoryContactCard(
                  name: contactName(patient),
                  subtitle: 'Village: ${patient['village'] ?? '—'}',
                  phone: contactPhone(patient),
                  peerUserId: peerId,
                  patientId: parseContactId(details['patient_id']) ?? peerId,
                  avatarIcon: Icons.person_outline,
                );
              },
            ),
    );
  }

  Widget _buildDoctorsTab() {
    if (_loadingDoctors) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _loadDoctors,
      child: _doctors.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text('No doctors registered yet')),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _doctors.length,
              itemBuilder: (context, index) {
                final doctor = _doctors[index];
                final peerId = parseContactId(doctor['user_id']);
                if (peerId == null) return const SizedBox.shrink();
                return DirectoryContactCard(
                  name: 'Dr. ${doctor['full_name'] ?? doctor['name'] ?? 'Doctor'}',
                  subtitle: doctor['specialization']?.toString() ?? 'General Physician',
                  phone: contactPhone(doctor),
                  peerUserId: peerId,
                  doctorId: parseContactId(doctor['id']),
                  avatarIcon: Icons.medical_services_outlined,
                );
              },
            ),
    );
  }
}
