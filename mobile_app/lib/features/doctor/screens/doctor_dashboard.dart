import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'consultation_history_screen.dart';
import 'create_prescription_screen.dart';
import 'doctor_notifications_screen.dart';
import 'my_patients_screen.dart';
import 'schedule_screen.dart';
import 'doctor_profile_screen.dart';
import 'asha_workers_screen.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/doctor_navigation_drawer.dart';
import '../../../providers/consultation_provider.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/api_service.dart';
import '../services/doctor_appointment_service.dart';
import '../../../core/services/permission_dialog_service.dart';
import '../../../core/widgets/sync_status_banner.dart';
import '../../../core/widgets/signaling_status_chip.dart';
import '../../../routes/app_routes.dart';
import '../../profile/widgets/profile_avatar.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int _selectedIndex = 0;
  bool _isLoading = false;
  int _patientCount = 0;
  int _ashaCount = 0;
  int _pendingAlerts = 0;
  int _virtualCalls = 0;
  String? _statsError;
  List<DoctorAppointment> _upcomingAppointments = [];
  final ApiService _api = ApiService();
  final DoctorAppointmentService _appointmentService = DoctorAppointmentService();

  @override
  void initState() {
    super.initState();
    _fetchStats();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<ConsultationProvider>().initSignaling(user.id.toString());
      }
      PermissionDialogService.ensureNotifications(context);
    });
  }

  Future<void> _fetchStats({bool isRetry = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      if (!isRetry) _statsError = null;
    });
    try {
      final patients = await _api.get('/users/patients/');
      final ashas = await _api.get('/users/asha-workers/');
      final alerts = await _api.get('/alerts/notifications/');
      final history = await _api.get('/consultations/history/');
      List<DoctorAppointment> appointments = [];
      try {
        appointments = await _appointmentService.getTodayAppointments();
      } catch (e) {
        debugPrint('Error fetching dashboard appointments: $e');
      }

      if (!mounted) return;
      setState(() {
        _patientCount = patients is List ? patients.length : 0;
        _ashaCount = ashas is List ? ashas.length : 0;
        _pendingAlerts = alerts is List ? alerts.length : 0;
        _virtualCalls = history is List ? history.length : 0;
        _statsError = null;
        _upcomingAppointments = appointments;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching doctor stats: $e');
      if (!isRetry) {
        await Future<void>.delayed(const Duration(seconds: 2));
        if (mounted) {
          await _fetchStats(isRetry: true);
          return;
        }
      }
      if (mounted) {
        setState(() {
          _statsError =
              'Could not load data from ${AppConfig.displayHost}. Log out and log in again.';
          _isLoading = false;
        });
      }
    }
  }

  final Color primaryBlue = const Color(0xFF2A7DE1);
  final Color lightBlue = const Color(0xFFE8F1FF);
  final Color cardBg = const Color(0xFFFFFFFF);
  final Color emergencyCardBg = const Color(0xFFFFE9E9);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const DoctorNavigationDrawer(activeRoute: 'Dashboard'),
      appBar: _selectedIndex == 0 ? _buildAppBar() : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeBody(),
          const MyPatientsScreen(embedded: true),
          const DoctorAshaWorkersScreen(embedded: true),
          const ScheduleScreen(embedded: true),
          const DoctorProfileScreen(embedded: true),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHomeBody() {
    return Column(
      children: [
        const SyncStatusBanner(),
        if (_statsError != null)
          Material(
            color: const Color(0xFFFFEBEE),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statsError!,
                      style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        _buildVerificationBanner(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchStats,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  if (_isLoading)
                    const LinearProgressIndicator(
                      minHeight: 2,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A7DE1)),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeSection(),
                        const SizedBox(height: 32),
                        _buildSectionTitle('PERFORMANCE SUMMARY'),
                        const SizedBox(height: 16),
                        _buildPerformanceGrid(),
                        const SizedBox(height: 32),
                        _buildSectionTitle('QUICK ACTIONS'),
                        const SizedBox(height: 16),
                        _buildQuickActions(),
                        const SizedBox(height: 32),
                        _buildUpcomingAppointments(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF8FAFC),
      elevation: 0,
      centerTitle: true,
      title: Text(
        'Doctor Dashboard',
        style: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: lightBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: primaryBlue, size: 20),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
        ),
      ),
      actions: [
        const Padding(
          padding: EdgeInsets.only(right: 4),
          child: Center(child: SignalingStatusChip(compact: true)),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: textPrimary,
                size: 28,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DoctorNotificationsScreen()),
                );
              },
            ),
            if (_pendingAlerts > 0)
              Positioned(
                right: 12,
                top: 14,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0, left: 4.0),
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
            child: ProfileAvatar(
              user: context.watch<AuthProvider>().user,
              radius: 17,
              backgroundColor: Colors.teal.shade700,
              iconColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, Dr. ${user?.name.split(' ').first ?? 'Doctor'}',
          style: TextStyle(
            color: textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'VitalReach · Phone: ${user?.phoneNumber ?? 'N/A'}',
          style: TextStyle(
            color: textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildPerformanceGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.assignment_outlined,
                iconColor: Colors.orange,
                iconBgColor: Colors.orange.withOpacity(0.1),
                title: 'PENDING ALERTS',
                value: '$_pendingAlerts',
                subtitle: 'High severity issues',
                badgeText: _pendingAlerts > 0 ? 'Action' : null,
                badgeColor: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.people_outline,
                iconColor: primaryBlue,
                iconBgColor: lightBlue,
                title: 'ASHA WORKERS',
                value: '$_ashaCount',
                subtitle: 'Active in region',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.people_alt_outlined,
                iconColor: Colors.teal,
                iconBgColor: Colors.teal.withOpacity(0.1),
                title: 'TOTAL PATIENTS',
                value: '$_patientCount',
                subtitle: 'Registered in system',
                subtitleColor: Colors.teal,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.video_call_outlined,
                iconColor: Colors.redAccent,
                iconBgColor: Colors.white,
                title: 'VIRTUAL CALLS',
                value: '$_virtualCalls',
                subtitle: 'Completed this month',
                subtitleColor: Colors.redAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String value,
    required String subtitle,
    Color? subtitleColor,
    String? badgeText,
    Color? badgeColor,
    Color? cardBackgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackgroundColor ?? cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: cardBackgroundColor != null
              ? Colors.redAccent.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cardBackgroundColor != null
                      ? Colors.white
                      : iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              if (badgeText != null)
                Flexible(
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor!.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: cardBackgroundColor != null
                  ? Colors.redAccent
                  : textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: subtitleColor ?? textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        _buildActionCard(
          icon: Icons.video_call_outlined,
          title: 'Start Consultation',
          isPrimary: true,
          onTap: () {
            setState(() => _selectedIndex = 1);
          },
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.person_search_outlined,
          title: 'View Patient List',
          onTap: () {
            setState(() => _selectedIndex = 1);
          },
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.health_and_safety_outlined,
          title: 'ASHA Workers',
          onTap: () {
            setState(() => _selectedIndex = 2);
          },
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.assignment,
          title: 'Create Prescription',
          onTap: () {
            _navigateTo(const CreatePrescriptionScreen());
          },
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.history,
          title: 'Consultation History',
          onTap: () {
            _navigateTo(const ConsultationHistoryScreen());
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    bool isPrimary = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isPrimary ? null : Colors.white,
          gradient: isPrimary
              ? LinearGradient(
                  colors: [primaryBlue, const Color(0xFF4CA0FF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary
              ? null
              : Border.all(color: Colors.grey.withOpacity(0.15)),
          boxShadow: [
            if (!isPrimary)
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: isPrimary ? Colors.white : primaryBlue, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: isPrimary ? Colors.white : const Color(0xFF334155),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Appointments',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() => _selectedIndex = 3); // Switch to Schedule tab
                  },
                  child: Text(
                    'View all',
                    style: TextStyle(
                      color: primaryBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          if (_upcomingAppointments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  'No appointments scheduled for today.',
                  style: TextStyle(color: textSecondary, fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _upcomingAppointments.take(3).length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 70, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final appt = _upcomingAppointments[index];
                String statusLabel = 'SCHEDULED';
                Color statusColor = Colors.green.shade700;
                Color statusBg = const Color(0xFFE8FDF0);

                if (appt.type == DoctorConsultationType.video) {
                  statusLabel = 'VIDEO CALL';
                  statusColor = primaryBlue;
                  statusBg = lightBlue;
                } else if (appt.type == DoctorConsultationType.audio) {
                  statusLabel = 'AUDIO CALL';
                  statusColor = const Color(0xFF10B981);
                  statusBg = const Color(0xFFECFDF5);
                } else if (appt.type == DoctorConsultationType.offline) {
                  statusLabel = 'OFFLINE';
                  statusColor = const Color(0xFFF59E0B);
                  statusBg = const Color(0xFFFEF3C7);
                }

                return _buildAppointmentItem(
                  name: appt.patientName,
                  condition: appt.historySummary.isNotEmpty && !appt.historySummary.startsWith('No previous')
                      ? appt.historySummary.split('\n').first
                      : (appt.notes.isNotEmpty ? appt.notes : 'General Consultation'),
                  time: appt.formattedTime,
                  statusText: statusLabel,
                  statusColor: statusColor,
                  statusBgColor: statusBg,
                  isLast: index == _upcomingAppointments.take(3).length - 1,
                  onTap: () {
                    setState(() => _selectedIndex = 3);
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAppointmentItem({
    required String name,
    required String condition,
    required String time,
    required String statusText,
    required Color statusColor,
    required Color statusBgColor,
    required bool isLast,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: isLast ? 20 : 16,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF1E293B),
              child: Text(
                name.isNotEmpty ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('') : 'P',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$condition · $time',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryBlue,
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedFontSize: 10,
        unselectedFontSize: 10,
        showUnselectedLabels: true,
        backgroundColor: Colors.white,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.home_outlined),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.home),
            ),
            label: 'HOME',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.people_alt_outlined),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.people),
            ),
            label: 'PATIENTS',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.health_and_safety_outlined),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.health_and_safety),
            ),
            label: 'ASHA',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.calendar_month_outlined),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.calendar_month),
            ),
            label: 'SCHEDULE',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.person_outline),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.person),
            ),
            label: 'PROFILE',
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBanner() {
    final user = context.watch<AuthProvider>().user;
    if (user == null || user.role != 'doctor') return const SizedBox.shrink();

    final status = user.detail('verification_status', fallback: 'INCOMPLETE');
    if (status == 'VERIFIED') return const SizedBox.shrink();

    Color bgColor;
    Color textColor;
    String title;
    String message;
    IconData icon;

    switch (status) {
      case 'PENDING_VERIFICATION':
        bgColor = const Color(0xFFFFF3CD);
        textColor = const Color(0xFF856404);
        title = 'VERIFICATION PENDING';
        message = 'Your medical credentials are currently being reviewed.';
        icon = Icons.hourglass_empty;
        break;
      case 'REJECTED':
        bgColor = const Color(0xFFFFE9E9);
        textColor = const Color(0xFFD92D20);
        title = 'VERIFICATION REJECTED';
        message = 'Reason: ${user.detail('rejection_reason', fallback: 'Please check your documents.')}';
        icon = Icons.error_outline;
        break;
      case 'INCOMPLETE':
      default:
        bgColor = const Color(0xFFFFE9E9);
        textColor = const Color(0xFFD92D20);
        title = 'UNVERIFIED';
        message = 'Complete your professional profile to unlock appointment and consultation features.';
        icon = Icons.warning_amber_rounded;
        break;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: 20, right: 20, top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
          if (status == 'INCOMPLETE' || status == 'REJECTED') ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.doctorVerification);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: textColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(0, 36),
              ),
              child: Text(status == 'REJECTED' ? 'Resubmit Documents' : 'Complete Profile'),
            ),
          ],
        ],
      ),
    );
  }
}
