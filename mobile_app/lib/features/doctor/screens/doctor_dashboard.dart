import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'consultation_history_screen.dart';
import 'create_prescription_screen.dart';
import 'doctor_notifications_screen.dart';
import 'my_patients_screen.dart';
import 'upcoming_consultations_screen.dart';
import 'schedule_screen.dart';
import 'doctor_profile_screen.dart';
import '../../../providers/auth_provider.dart';
import 'doctor_settings_screen.dart';
import '../services/settings_service.dart';
import 'package:hs053/features/user/services/doctor_service.dart';
import '../widgets/doctor_navigation_drawer.dart';
import 'prescription_history_screen.dart';

import '../../../providers/consultation_provider.dart';
import '../../../core/utils/app_translations.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int _selectedIndex = 0;
  final DoctorService _doctorService = DoctorService();
  Map<String, dynamic> _stats = {
    'pending_count': 0,
    'appointments_today': 0,
    'total_patients': 0,
    'emergency_count': 0,
  };
  bool _isLoadingStats = true;
  List<dynamic> _appointments = [];
  bool _isLoadingAppointments = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardStats();
    _fetchTodayAppointments();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<ConsultationProvider>().initSignaling(user.id.toString());
      }
    });
  }

  Future<void> _fetchDashboardStats() async {
    try {
      final stats = await _doctorService.getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  Future<void> _fetchTodayAppointments() async {
    try {
      final appointments = await _doctorService.getTodayAppointments();
      if (mounted) {
        setState(() {
          _appointments = appointments;
          _isLoadingAppointments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAppointments = false);
      }
    }
  }

  final Color primaryBlue = const Color(0xFF2A7DE1);
  final Color lightBlue = const Color(0xFFE8F1FF);
  final Color cardBg = const Color(0xFFFFFFFF);
  final Color emergencyCardBg = const Color(0xFFFFE9E9);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);

  void _onItemTapped(int index) async {
    if (index == 0) return;
    
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      await _navigateTo(const MyPatientsScreen());
    } else if (index == 2) {
      await _navigateTo(const ScheduleScreen());
    } else if (index == 3) {
      await _navigateTo(const DoctorProfileScreen());
    }
    
    if (mounted) {
      setState(() {
        _selectedIndex = 0;
      });
    }
  }

  Future<void> _navigateTo(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const DoctorNavigationDrawer(activeRoute: 'Dashboard'),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 32),
              _buildSectionTitle('perf_summary'.tr(context)),
              const SizedBox(height: 16),
              _buildPerformanceGrid(),
              const SizedBox(height: 32),
              _buildSectionTitle('quick_actions'.tr(context)),
              const SizedBox(height: 16),
              _buildQuickActions(),
              const SizedBox(height: 32),
              _buildUpcomingAppointments(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF8FAFC),
      elevation: 0,
      centerTitle: true,
      title: Text(
        'doctor_dashboard'.tr(context),
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
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DoctorProfileScreen()),
            ).then((_) => _fetchDashboardStats());
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 4.0),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: Colors.teal.shade700,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
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
          '${'welcome'.tr(context)}, Dr. ${user?.name ?? 'doctor'.tr(context)}',
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
                title: 'pending'.tr(context),
                value: _stats['pending_count'].toString(),
                subtitle: 'waiting_approval'.tr(context),
                badgeText: _stats['pending_count'] > 0 ? 'urgent'.tr(context) : null,
                badgeColor: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.calendar_today_outlined,
                iconColor: primaryBlue,
                iconBgColor: lightBlue,
                title: 'appointments'.tr(context),
                value: _stats['appointments_today'].toString(),
                subtitle: 'scheduled_today'.tr(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.people_outline,
                iconColor: Colors.teal,
                iconBgColor: Colors.teal.withOpacity(0.1),
                title: 'total_patients'.tr(context),
                value: _stats['total_patients'].toString(),
                subtitle: 'patients_increase'.tr(context),
                subtitleColor: Colors.teal,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.local_hospital_outlined,
                iconColor: Colors.redAccent,
                iconBgColor: Colors.white,
                title: 'emergency'.tr(context),
                value: _stats['emergency_count'].toString(),
                subtitle: 'action_required'.tr(context),
                subtitleColor: Colors.redAccent,
                cardBackgroundColor: emergencyCardBg,
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
          title: 'start_consultation'.tr(context),
          isPrimary: true,
          onTap: () {
            _navigateTo(const UpcomingConsultationsScreen());
          },
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.person_search_outlined,
          title: 'view_patient_list'.tr(context),
          onTap: () {
            _navigateTo(const MyPatientsScreen());
          },
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.assignment,
          title: 'Create Prescription',
          onTap: () {
            _navigateTo(const MyPatientsScreen());
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a patient to create a prescription')),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.history,
          title: 'Prescription History',
          onTap: () {
            _navigateTo(PrescriptionHistoryScreen());
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
                  'upcoming_appointments'.tr(context),
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                InkWell(
                  onTap: () => _onItemTapped(2), // Navigate to Schedule
                  child: Text(
                    'view_all'.tr(context),
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
          if (_isLoadingAppointments)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_appointments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'no_appointments_today'.tr(context),
                  style: TextStyle(color: textSecondary),
                ),
              ),
            )
          else
            ..._appointments.take(3).map((appt) {
              final isLast = _appointments.indexOf(appt) == (_appointments.length < 3 ? _appointments.length - 1 : 2);
              return Column(
                children: [
                  _buildAppointmentItem(
                    name: appt['patient_name'],
                    condition: appt['notes']?.isNotEmpty == true ? appt['notes'] : 'General Checkup',
                    time: appt['time'],
                    statusText: appt['type'] == 'VIDEO' ? 'VIDEO CALL' : 'AUDIO CALL',
                    statusColor: appt['type'] == 'VIDEO' ? primaryBlue : Colors.green.shade700,
                    statusBgColor: appt['type'] == 'VIDEO' ? lightBlue : const Color(0xFFE8FDF0),
                    isLast: isLast,
                  ),
                  if (!isLast) const Divider(height: 1, indent: 70, color: Color(0xFFF1F5F9)),
                ],
              );
            }).toList(),
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
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: isLast ? 20 : 16,
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFF1E293B),
            child: Icon(Icons.person, color: Colors.white70),
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
        items: [
          BottomNavigationBarItem(
            icon: const Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.home_outlined),
            ),
            activeIcon: const Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.home),
            ),
            label: 'home'.tr(context),
          ),
          BottomNavigationBarItem(
            icon: const Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.people_alt_outlined),
            ),
            activeIcon: const Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.people),
            ),
            label: 'my_patients'.tr(context),
          ),
          BottomNavigationBarItem(
            icon: const Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.calendar_month_outlined),
            ),
            activeIcon: const Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.calendar_month),
            ),
            label: 'schedule'.tr(context),
          ),
          BottomNavigationBarItem(
            icon: const Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.person_outline),
            ),
            activeIcon: const Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.person),
            ),
            label: 'profile'.tr(context),
          ),
        ],
      ),
    );
  }
}
