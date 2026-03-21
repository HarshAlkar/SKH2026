import 'package:flutter/material.dart';
import '../../../core/widgets/common_appbar.dart';
import '../../../routes/app_routes.dart';
import '../../asha_worker/widgets/asha_drawer.dart';
import '../models/alert_model.dart';
import '../widgets/alert_card.dart';
import 'create_alert_screen.dart';
import '../../../core/services/api_service.dart';

class RiskAlertScreen extends StatefulWidget {
  const RiskAlertScreen({super.key});

  @override
  State<RiskAlertScreen> createState() => _RiskAlertScreenState();
}

class _RiskAlertScreenState extends State<RiskAlertScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  List<AlertModel> _allAlerts = [];
  List<AlertModel> _filteredAlerts = [];
  bool _isLoading = true;
  String? _error;

  final Color primaryColor = const Color(0xFF2F4DB6);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAlerts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // By convention, your alert endpoint is exposed at /alerts/notifications/ 
      // based on django routing schema configuration
      final response = await _apiService.get('/alerts/notifications/');
      final List<AlertModel> fetched = (response as List)
          .map((data) => AlertModel.fromJson(data))
          .toList();

      if (mounted) {
        setState(() {
          _allAlerts = fetched;
          _filteredAlerts = _allAlerts;
          _isLoading = false;
        });
        _filterAlerts(_searchController.text);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _filterAlerts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredAlerts = _allAlerts;
      } else {
        _filteredAlerts = _allAlerts
            .where(
              (alert) =>
                  alert.patientName.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const CommonAppBar(
        title: "Health Risk Alerts",
        showProfile: true,
      ),
      drawer: const AshaDrawer(currentRoute: AppRoutes.riskAlerts),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const CreateAlertScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            ),
          ).then((value) {
             // Re-fetch automatically if a new alert is generated in manual screen later
             if (value == true) {
               _fetchAlerts();
             }
          });
        },
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: backgroundColor,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterAlerts,
                  decoration: InputDecoration(
                    hintText: 'Search alerts by patient name...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),
            ),

            // Alert List Dynamically Handled
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           const Icon(Icons.error_outline, size: 50, color: Colors.redAccent),
                           const SizedBox(height: 16),
                           Text("Error: $_error", style: const TextStyle(color: Colors.redAccent)),
                           const SizedBox(height: 16),
                           ElevatedButton(
                             onPressed: _fetchAlerts,
                             child: const Text("Retry"),
                           )
                        ],
                      )
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchAlerts,
                      child: _filteredAlerts.isEmpty 
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              Container(
                                padding: const EdgeInsets.only(top: 100),
                                alignment: Alignment.center,
                                child: Column(
                                  children: const [
                                     Icon(Icons.safety_check, size: 60, color: Colors.grey),
                                     SizedBox(height: 16),
                                     Text("No active risk alerts.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                                  ],
                                ),
                              )
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            itemCount: _filteredAlerts.length,
                            itemBuilder: (context, index) {
                              return AlertCard(alert: _filteredAlerts[index]);
                            },
                          ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
