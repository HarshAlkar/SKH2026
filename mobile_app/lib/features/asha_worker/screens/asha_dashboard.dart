import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/stats_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/asha_drawer.dart';
import '../widgets/activity_tile.dart';
import '../widgets/emergency_button.dart';
import '../widgets/asha_sidebar.dart';
import 'package:hs053/shared/providers/auth_provider.dart';
import 'package:hs053/core/services/api_service.dart';
import 'package:hs053/core/routes/app_routes.dart';

class AshaDashboard extends StatefulWidget {
  const AshaDashboard({super.key});

  @override
  State<AshaDashboard> createState() => _AshaDashboardState();
}

class _AshaDashboardState extends State<AshaDashboard> {
  final Color primaryColor = const Color(0xFF2A7DE1);
  final Color lightBackground = const Color(0xFFF5F7FA);
  
  bool _isLoading = true;
  int _totalPatients = 0;
  int _highRiskCount = 0;
  int _newAlerts = 0;
  List<dynamic> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    final api = ApiService();
    try {
      // Fetch patients count
      final patients = await api.get('/users/patients/');
      // Fetch alerts
      final alerts = await api.get('/alerts/notifications/');
      
      setState(() {
        _totalPatients = patients.length;
        _newAlerts = alerts.length;
        _highRiskCount = alerts.where((a) => a['severity'] == 'High' || a['severity'] == 'Critical').length;
        _recentActivity = alerts.take(3).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching asha dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: lightBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDashboardData,
          ),
          const SizedBox(width: 8)
        ],
      ),
      drawer: const AshaSidebar(),
      floatingActionButton: EmergencyButton(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Emergency Alert sent to PHC')),
          );
        },
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchDashboardData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
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
                            "Welcome, ${user?.name.split(' ').first ?? 'ASHA'} 👋",
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
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Stats Cards Grid
                if (_isLoading)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ))
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
                        number: "12",
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
                            label: "List Patients",
                            onTap: () => Navigator.pushNamed(context, AppRoutes.villagePatients),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: QuickActionButton(
                            icon: Icons.edit_document,
                            label: "Update Health",
                            onTap: () => Navigator.pushNamed(context, AppRoutes.updateHealth),
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
                            onTap: () => Navigator.pushNamed(context, AppRoutes.riskAlerts),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: QuickActionButton(
                            icon: Icons.medical_services_outlined,
                            label: "Consult Doctor",
                            onTap: () => Navigator.pushNamed(context, AppRoutes.registeredDoctors),
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
                      "RECENT ALERTS",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Colors.grey,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.riskAlerts),
                      child: const Text("View All"),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_recentActivity.isEmpty && !_isLoading)
                   const Center(child: Text("No recent alerts in your village"))
                else
                  ..._recentActivity.map((alert) => ActivityTile(
                    icon: Icons.warning_amber_rounded,
                    name: alert['patient_name'] ?? "Unknown Patient",
                    activity: "${alert['disease']} • ${alert['severity']}",
                    iconBackgroundColor: alert['severity'] == 'High' ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    iconColor: alert['severity'] == 'High' ? Colors.red : Colors.orange,
                    onTap: () {},
                  )),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
