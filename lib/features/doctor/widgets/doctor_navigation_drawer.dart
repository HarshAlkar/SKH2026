import 'package:flutter/material.dart';
import '../screens/doctor_dashboard.dart';
import '../screens/doctor_login_screen.dart';
import '../screens/patient_requests_screen.dart';
import '../screens/create_prescription_screen.dart';
import '../screens/consultation_history_screen.dart';
import '../screens/health_reports_screen.dart';

class DoctorNavigationDrawer extends StatelessWidget {
  final String activeRoute;

  const DoctorNavigationDrawer({super.key, this.activeRoute = 'Dashboard'});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2A7DE1);
    const textDark = Color(0xFF334155);
    const textGrey = Color(0xFF94A3B8);
    const dividerColor = Color(0xFFF1F5F9);

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // PROFILE HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Icon(
                          Icons.person,
                          size: 36,
                          color: primaryBlue.withOpacity(0.5),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF10B981,
                            ), // Green online indicator
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dr. Amit Sharma',
                          style: TextStyle(
                            color: textDark,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'General Physician',
                          style: TextStyle(
                            color: textGrey,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: dividerColor, height: 1),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // MAIN MENU SECTION
                    _buildSectionTitle('MAIN MENU'),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.grid_view_rounded,
                      title: 'Dashboard',
                      isActive: activeRoute == 'Dashboard',
                      onTap: () {
                        Navigator.pop(context); // close drawer
                        if (activeRoute != 'Dashboard') {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DoctorDashboard(),
                            ),
                          );
                        }
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.person_add_alt_1_outlined,
                      title: 'Patient Requests',
                      isActive: activeRoute == 'Patient Requests',
                      badge: '12',
                      onTap: () {
                        Navigator.pop(context);
                        if (activeRoute != 'Patient Requests') {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const PatientRequestsScreen()),
                          );
                        }
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.people_alt_outlined,
                      title: 'My Patients',
                      isActive: activeRoute == 'My Patients',
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.medical_services_outlined,
                      title: 'Consultations',
                      isActive: activeRoute == 'Consultations',
                      onTap: () {
                        Navigator.pop(context);
                        if (activeRoute != 'Consultations') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ConsultationHistoryScreen()),
                          );
                        }
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.assignment_outlined,
                      title: 'Prescriptions',
                      isActive: activeRoute == 'Prescriptions',
                      onTap: () {
                        Navigator.pop(context);
                        if (activeRoute != 'Prescriptions') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CreatePrescriptionScreen()),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    // INSIGHTS & SETTINGS SECTION
                    _buildSectionTitle('INSIGHTS & SETTINGS'),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.bar_chart_rounded,
                      title: 'Reports',
                      isActive: activeRoute == 'Reports',
                      onTap: () {
                        Navigator.pop(context);
                        if (activeRoute != 'Reports') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const HealthReportsScreen()),
                          );
                        }
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      isActive: activeRoute == 'Settings',
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const Divider(color: dividerColor, height: 1),

            // FOOTER - LOGOUT
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DoctorLoginScreen(),
                    ),
                    (route) => false,
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: Colors.redAccent,
                        size: 22,
                      ),
                      SizedBox(width: 16),
                      Text(
                        'Logout Account',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool isActive,
    String? badge,
    required VoidCallback onTap,
  }) {
    const primaryBlue = Color(0xFF2A7DE1);
    const activeBg = Color(0xFFE8F1FF);
    const textDark = Color(0xFF475569);
    const activeText = Color(0xFF1E40AF);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isActive ? activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: isActive ? primaryBlue : textDark, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isActive ? activeText : textDark,
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
