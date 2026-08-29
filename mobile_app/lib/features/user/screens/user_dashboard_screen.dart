import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/medicine_provider.dart';
import '../widgets/user_sidebar.dart';
import '../../profile/widgets/profile_avatar.dart';


import '../../../providers/consultation_provider.dart';
import '../../../core/sync/offline_api.dart';
import '../../../core/widgets/sync_status_banner.dart';
import '../../../core/services/permission_dialog_service.dart';
import 'asha_workers_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  bool _showReminder = true;
  Map<String, dynamic>? _assignedAsha;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<ConsultationProvider>().initSignaling(user.id.toString());
      }
      PermissionDialogService.ensureNotifications(context);
      context.read<MedicineProvider>().loadMedicines();
      _loadAssignedAsha();
    });
  }

  Future<void> _loadAssignedAsha() async {
    try {
      final data = await OfflineApi.instance.get('/users/asha-workers/');
      if (!mounted) return;
      if (data is List && data.isNotEmpty) {
        setState(() => _assignedAsha = Map<String, dynamic>.from(data.first as Map));
      }
    } catch (_) {}
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.primary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'VitalReach',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: AppColors.primary),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.patientAlerts),
          ),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                  child: ProfileAvatar(
                    user: auth.user,
                    radius: 18,
                    backgroundColor: AppColors.lightBlue,
                    iconColor: AppColors.primary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      drawer: const UserSidebar(),
      body: Column(
        children: [
          const SyncStatusBanner(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(),
                  if (_assignedAsha != null) _buildAssignedAshaCard(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSymptomCheckerCard(),
                        const SizedBox(height: 24),
                        const Text(
                          'Quick Actions',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 16),
                        _buildQuickActionsGrid(),
                        const SizedBox(height: 24),
                        _buildMedicineReminder(),
                        const Text(
                          "Today's Health Tips",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 16),
                        _buildHealthTipsList(),
                        const SizedBox(height: 24),
                        _buildEmergencyCard(),
                        const SizedBox(height: 40),
                      ],
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


  Widget _buildAssignedAshaCard() {
    final name = _assignedAsha?['name']?.toString() ?? 'ASHA Worker';
    final phone = _assignedAsha?['phone_number']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AshaWorkersScreen()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightBlue,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.health_and_safety, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ASHA workers in your village',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (phone.isNotEmpty)
                      Text(
                        phone,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final name = auth.user?.name ?? 'User';
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          decoration: const BoxDecoration(
            color: Color(0xFFE8F1FF),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello $name 👋',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 4),
              const Text(
                'How are you feeling today?',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSymptomCheckerCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A7DE1), Color(0xFF4A90E2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A7DE1).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Opacity(
              opacity: 0.1,
              child: Image.asset('assets/images/health_icon.png', width: 120, color: Colors.white),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.heart_broken_outlined, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'AI Symptom \nChecker',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Check your symptoms and get \ninstant guidance.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.symptomChecker),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 0,
                ),
                child: const Text('Check Symptoms', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildActionCard('Book Appointment', Icons.calendar_month_outlined, AppRoutes.bookAppointment),
        _buildActionCard('My Appointments', Icons.event_available_outlined, AppRoutes.patientAppointments),
        _buildActionCard('Medicine Tracker', Icons.medication_outlined, AppRoutes.medicineTracker),
        _buildActionCard('Nearby Clinics', Icons.location_on_outlined, AppRoutes.nearbyClinics),
        _buildActionCard('Consult Doctor', Icons.video_camera_front_outlined, AppRoutes.consultDoctor),
        _buildActionCard('ASHA Workers', Icons.health_and_safety_outlined, AppRoutes.ashaWorkers),
        _buildActionCard('My Prescriptions', Icons.description_outlined, AppRoutes.myPrescriptions),
        _buildActionCard('Health Tips', Icons.lightbulb_outline, AppRoutes.healthTips),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, String route) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineReminder() {
    if (!_showReminder) return const SizedBox.shrink();
    return Consumer<MedicineProvider>(
      builder: (context, medProvider, _) {
        final todaysMeds = medProvider.todaysMedicines;
        if (todaysMeds.isEmpty) return const SizedBox.shrink();

        // Find next untaken medicine for today
        final now = DateTime.now();
        final upcoming = todaysMeds.where((m) => !medProvider.isTakenOn(m.id ?? 0, now)).toList();
        final med = upcoming.isNotEmpty ? upcoming.first : null;
        if (med == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.pushNamed(context, AppRoutes.medicineTracker),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.medication_outlined, color: AppColors.primary, size: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.medicineTracker),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${med.medicineName} reminder',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Scheduled at ${med.reminderTime}${med.dosage.isNotEmpty ? ' • ${med.dosage}' : ''}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _showReminder = false),
                child: const Text('DISMISS', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHealthTipsList() {
    return SizedBox(
      height: 140,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildTipCard('Stay Hydrated', 'Drink at least 8 glasses of \nwater daily.', Icons.water_drop_outlined, const Color(0xFFE8F1FF)),
          const SizedBox(width: 16),
          _buildTipCard('Morning Walk', 'A 15-minute walk boosts \nyour energy.', Icons.directions_run_outlined, const Color(0xFFEFFFFA)),
          const SizedBox(width: 16),
          _buildTipCard('Sleep Well', 'Get 7-8 hours of quality sleep \nevery night.', Icons.bedtime_outlined, const Color(0xFFFFF7EF)),
        ],
      ),
    );
  }

  Widget _buildTipCard(String title, String subtitle, IconData icon, Color bgColor) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueGrey, size: 24),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emergency_outlined, color: Colors.red, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Help',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Immediate medical support',
                  style: TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.emergencyHelp),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              elevation: 0,
            ),
            child: const Text('Call Emergency', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}


