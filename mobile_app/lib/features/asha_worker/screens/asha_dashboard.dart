import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/stats_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/activity_tile.dart';
import '../widgets/emergency_button.dart';
import '../widgets/asha_sidebar.dart';
import '../../../l10n/l10n.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user_model.dart';
import '../../../core/config/app_config.dart';
import '../../../core/sync/offline_api.dart';
import '../../../core/widgets/sync_status_banner.dart';
import '../../../core/widgets/signaling_status_chip.dart';
import '../../../core/widgets/simulate_blackout_button.dart';
import '../../../providers/consultation_provider.dart';
import '../../../core/services/permission_dialog_service.dart';
import '../../../routes/app_routes.dart';
import '../../patient/screens/village_patients_screen.dart';
import 'asha_call_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../profile/widgets/profile_avatar.dart';

class AshaDashboard extends StatefulWidget {
  const AshaDashboard({super.key});

  @override
  State<AshaDashboard> createState() => _AshaDashboardState();
}

class _AshaDashboardState extends State<AshaDashboard> {
  final Color primaryColor = const Color(0xFF2A7DE1);
  final Color lightBackground = const Color(0xFFF5F7FA);
  int _selectedIndex = 0;

  bool _isLoading = true;
  int _totalPatients = 0;
  int _highRiskCount = 0;
  int _newAlerts = 0;
  int _pendingVisits = 0;
  String? _dashboardError;
  List<dynamic> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<ConsultationProvider>().initSignaling(user.id.toString());
      }
      PermissionDialogService.ensureNotifications(context);
    });
  }

  Future<void> _fetchDashboardData({bool isRetry = false}) async {
    setState(() {
      _isLoading = true;
      if (!isRetry) _dashboardError = null;
    });
    final api = OfflineApi.instance;
    try {
      final dash = await api.get('/asha/dashboard/');
      final stats = dash is Map ? dash['stats'] : null;
      setState(() {
        _totalPatients = _asInt(stats is Map ? stats['total_patients'] : 0);
        _highRiskCount = _asInt(stats is Map ? stats['high_risk_alerts'] : 0);
        _pendingVisits = _asInt(stats is Map ? stats['pending_visits'] : 0);
        _newAlerts = _asInt(stats is Map ? stats['new_alerts'] : 0);
        _recentActivity = dash is Map && dash['recent_activity'] is List
            ? List.from(dash['recent_activity'])
            : [];
        _dashboardError = null;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching asha dashboard data: $e');
      if (!isRetry) {
        await Future<void>.delayed(const Duration(seconds: 2));
        if (mounted) {
          await _fetchDashboardData(isRetry: true);
          return;
        }
      }
      setState(() {
        _dashboardError =
            context.l10n.couldNotLoadData(AppConfig.displayHost);
        _isLoading = false;
      });
    }
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  Future<void> _openAndRefresh(String route) async {
    await Navigator.pushNamed(context, route);
    if (mounted) await _fetchDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: lightBackground,
      drawer: const AshaSidebar(),
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: lightBackground,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black87),
              actions: [
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Center(child: SignalingStatusChip(compact: true)),
                ),
                const SimulateBlackoutButton(compact: true),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchDashboardData,
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      floatingActionButton: _selectedIndex == 0
          ? EmergencyButton(
              onTap: () => _openAndRefresh(AppRoutes.emergencyReferral),
            )
          : null,
      body: Column(
        children: [
          const SyncStatusBanner(),
          if (_dashboardError != null)
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
                        _dashboardError!,
                        style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildHomeBody(user),
                const VillagePatientsScreen(embedded: true),
                const AshaCallScreen(embedded: true),
                const ProfileScreen(embedded: true),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  void _showUnverifiedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please verify your profile to unlock this feature.')),
    );
  }

  Widget _buildHomeBody(UserModel? user) {
    final isVerified = user?.getDetail('verification_status', fallback: 'INCOMPLETE') == 'VERIFIED';

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVerificationBanner(user),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome, ${user == null || user.name.trim().isEmpty ? 'ASHA' : user.name.split(' ').first} 👋",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Village: ${user?.village ?? 'Unknown'}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _selectedIndex = 3),
                    child: ProfileAvatar(
                      user: user,
                      radius: 24,
                      backgroundColor: Colors.white,
                      iconColor: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => _openAndRefresh(AppRoutes.riskAlerts),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.0,
                  children: [
                    StatsCard(
                      icon: Icons.people_alt_outlined,
                      number: "$_totalPatients",
                      label: "PATIENTS",
                      iconColor: primaryColor,
                      iconBackgroundColor: primaryColor.withOpacity(0.1),
                    ),
                    StatsCard(
                      icon: Icons.monitor_heart_outlined,
                      number: "$_highRiskCount",
                      label: "HIGH RISK",
                      iconColor: Colors.redAccent,
                      iconBackgroundColor: Colors.redAccent.withOpacity(0.1),
                    ),
                    StatsCard(
                      icon: Icons.calendar_month_outlined,
                      number: "$_pendingVisits",
                      label: "PENDING VISITS",
                      iconColor: Colors.orange,
                      iconBackgroundColor: Colors.orange.withOpacity(0.1),
                    ),
                    StatsCard(
                      icon: Icons.notifications_none_outlined,
                      number: "$_newAlerts",
                      label: "NEW ALERTS",
                      iconColor: const Color(0xFF4A90E2),
                      iconBackgroundColor: const Color(0xFF4A90E2).withOpacity(0.1),
                    ),
                  ],
                ),
              const SizedBox(height: 32),
              const Text(
                "QUICK ACTIONS",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: QuickActionButton(
                          icon: Icons.person_add_outlined,
                          label: "List Patients",
                          onTap: isVerified ? () => setState(() => _selectedIndex = 1) : _showUnverifiedMessage,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: QuickActionButton(
                          icon: Icons.edit_document,
                          label: "Update Health",
                          onTap: isVerified ? () => _openAndRefresh(AppRoutes.updateHealth) : _showUnverifiedMessage,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: QuickActionButton(
                          icon: Icons.warning_amber_rounded,
                          label: "View Alerts",
                          onTap: isVerified ? () => _openAndRefresh(AppRoutes.riskAlerts) : _showUnverifiedMessage,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: QuickActionButton(
                          icon: Icons.call_outlined,
                          label: "Call / Chat",
                          onTap: isVerified ? () => setState(() => _selectedIndex = 2) : _showUnverifiedMessage,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: QuickActionButton(
                          icon: Icons.verified_user_outlined,
                          label: "Verify Health Info",
                          onTap: isVerified
                              ? () => _openAndRefresh(AppRoutes.verifyHealthInfo)
                              : _showUnverifiedMessage,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "RECENT VISITS",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Colors.grey,
                    ),
                  ),
                  TextButton(
                    onPressed: isVerified ? () => _openAndRefresh(AppRoutes.villageVisits) : null,
                    child: const Text("View All"),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_recentActivity.isEmpty && !_isLoading)
                const Center(child: Text("No recent visits in your village"))
              else
                ..._recentActivity.map(
                  (item) => ActivityTile(
                    icon: Icons.home_outlined,
                    name: item['patient_name'] ?? "Unknown Patient",
                    activity:
                        "${item['disease'] ?? ''} • ${item['severity'] ?? ''}",
                    iconBackgroundColor: item['severity'] == 'COMPLETED'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    iconColor: item['severity'] == 'COMPLETED'
                        ? Colors.green
                        : Colors.orange,
                    onTap: () {},
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
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
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
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
              child: Icon(Icons.people_outline),
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
              child: Icon(Icons.call_outlined),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.call),
            ),
            label: 'CALL',
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

  Widget _buildVerificationBanner(UserModel? user) {
    if (user == null || user.role != 'asha_worker') return const SizedBox.shrink();

    final status = user.getDetail('verification_status', fallback: 'INCOMPLETE');
    if (status == 'VERIFIED') return const SizedBox.shrink();

    Color bgColor;
    Color textColor;
    IconData icon;
    String title;
    String message;
    String buttonText = 'Complete Profile';
    VoidCallback onTap = () => _openAndRefresh(AppRoutes.ashaVerification);

    switch (status) {
      case 'PENDING_VERIFICATION':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade900;
        icon = Icons.pending_actions;
        title = 'VERIFICATION PENDING';
        message = 'Your ASHA Worker credentials are being reviewed.';
        buttonText = 'View Status';
        break;
      case 'REJECTED':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade900;
        icon = Icons.error_outline;
        title = 'VERIFICATION REJECTED';
        message = 'Reason: ${user.getDetail('rejection_reason', fallback: 'Unknown')}';
        buttonText = 'Update Documents';
        break;
      case 'INCOMPLETE':
      default:
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade900;
        icon = Icons.warning_amber_rounded;
        title = 'UNVERIFIED';
        message = 'Complete your profile to unlock professional ASHA Worker features.';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
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
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: textColor, fontSize: 13)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: textColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }
}
