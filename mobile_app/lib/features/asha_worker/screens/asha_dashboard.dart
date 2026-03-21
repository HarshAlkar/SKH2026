import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../routes/app_routes.dart';
import '../../../core/widgets/common_appbar.dart';
import '../widgets/stats_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/asha_drawer.dart';
import '../widgets/activity_tile.dart';
import '../../notifications/widgets/notification_badge.dart';
import '../../activity/models/activity_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../providers/auth_provider.dart';

class AshaDashboard extends StatefulWidget {
  const AshaDashboard({super.key});

  @override
  State<AshaDashboard> createState() => _AshaDashboardState();
}

class _AshaDashboardState extends State<AshaDashboard> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _stats;
  List<dynamic>? _recentActivity;
  String _workerName = "ASHA Worker";
  String _village = "Unknown Village";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user != null) {
      _workerName = user.name;
      _village = user.village;
    }
  }

  final Color primaryColor = const Color(0xFF2A7DE1);
  final Color secondaryBlue = const Color(0xFF4A90E2);
  final Color lightBackground = const Color(0xFFF5F7FA);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.get(
        ApiConstants.ashaDashboardEndpoint,
      );
      setState(() {
        _stats = response['stats'];
        _recentActivity = response['recent_activity'];
        _workerName = response['worker_name'] ?? _workerName;
        _village = response['village'] ?? _village;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Helper method to format date slightly nicer
  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      // Rough time ago
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 0) return '${diff.inDays} days ago';
      if (diff.inHours > 0) return '${diff.inHours} hrs ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes} mins ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const CommonAppBar(
        title: "ASHA Dashboard",
        showNotification: false,
      ),
      drawer: const AshaDrawer(currentRoute: AppRoutes.ashaDashboard),
      floatingActionButton: null,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: $_error',
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchDashboardData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _fetchDashboardData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Hello $_workerName 👋",
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "$_village Health Overview",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.ashaNotifications,
                                  );
                                },
                              ),
                              if (_stats != null &&
                                  (_stats!['new_alerts'] ?? 0) > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: NotificationBadge(
                                    count: _stats!['new_alerts'],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Stats Cards Grid
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.0,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.villagePatients,
                            ),
                            child: StatsCard(
                              icon: Icons.people_alt_outlined,
                              number:
                                  _stats?['total_patients']?.toString() ?? "0",
                              label: "TOTAL PATIENTS",
                              iconColor: primaryColor,
                              iconBackgroundColor: primaryColor.withOpacity(
                                0.1,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.riskAlerts,
                            ),
                            child: StatsCard(
                              icon: Icons.monitor_heart_outlined,
                              number:
                                  _stats?['high_risk_alerts']?.toString() ??
                                  "0",
                              label: "HIGH RISK",
                              iconColor: Colors.redAccent,
                              iconBackgroundColor: Colors.redAccent.withOpacity(
                                0.1,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.villageVisits,
                            ),
                            child: StatsCard(
                              icon: Icons.calendar_month_outlined,
                              number:
                                  _stats?['pending_visits']?.toString() ?? "0",
                              label: "PENDING VISITS",
                              iconColor: Colors.orange,
                              iconBackgroundColor: Colors.orange.withOpacity(
                                0.1,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.ashaNotifications,
                            ),
                            child: StatsCard(
                              icon: Icons.notifications_none_outlined,
                              number: _stats?['new_alerts']?.toString() ?? "0",
                              label: "NEW ALERTS",
                              iconColor: secondaryBlue,
                              iconBackgroundColor: secondaryBlue.withOpacity(
                                0.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Quick Actions
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
                                  label: "Register Patient",
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.villagePatients,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: QuickActionButton(
                                  icon: Icons.edit_document,
                                  label: "Update Health",
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.updateHealth,
                                  ),
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
                                  label: "View Risk Alerts",
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.riskAlerts,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: QuickActionButton(
                                  icon: Icons.analytics_outlined,
                                  label: "Health Report",
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.villageHealthReport,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: QuickActionButton(
                                  icon: Icons.medical_services_outlined,
                                  label: "Consult Doctor",
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.ashaConsultDoctor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Recent Activity Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "RECENT ACTIVITY",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: Colors.grey,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.ashaAllActivity,
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              "View All",
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_recentActivity == null || _recentActivity!.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text(
                              "No recent activity to show.",
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._recentActivity!.map((activity) {
                          bool isError = activity['icon_type'] == 'error';
                          return ActivityTile(
                            icon: isError
                                ? Icons.error_outline
                                : Icons.warning_amber_rounded,
                            name: activity['patientName'] ?? 'Unknown',
                            activity:
                                "${activity['description']} • ${_formatDate(activity['timestamp'] ?? '')}",
                            iconBackgroundColor: isError
                                ? const Color(0xFFFFEBEE)
                                : const Color(0xFFFFF7E6),
                            iconColor: isError
                                ? Colors.redAccent
                                : Colors.orange,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.ashaActivityDetails,
                                arguments: ActivityModel(
                                  id: activity['id'].toString(),
                                  patientName:
                                      activity['patientName'] ?? 'Unknown',
                                  activityType:
                                      activity['activityType'] ?? 'Alert',
                                  description: activity['description'] ?? '',
                                  timestamp:
                                      DateTime.tryParse(
                                        activity['timestamp'],
                                      ) ??
                                      DateTime.now(),
                                  village: _village,
                                  reportedBy: 'System',
                                ),
                              );
                            },
                          );
                        }),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
