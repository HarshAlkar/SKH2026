import 'package:flutter/material.dart';

import '../../../core/sync/offline_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../alerts/models/alert_model.dart';
import '../widgets/user_sidebar.dart';

class PatientAlertsScreen extends StatefulWidget {
  const PatientAlertsScreen({super.key});

  @override
  State<PatientAlertsScreen> createState() => _PatientAlertsScreenState();
}

class _PatientAlertsScreenState extends State<PatientAlertsScreen> {
  final OfflineApi _api = OfflineApi.instance;
  bool _loading = true;
  String? _error;
  List<AlertModel> _alerts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _api.get('/alerts/notifications/');
      final rows = response is List ? response : <dynamic>[];
      setState(() {
        _alerts = rows
            .whereType<Map>()
            .map((row) => AlertModel.fromNotification(Map<String, dynamic>.from(row)))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load notifications';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const UserSidebar(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.primary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: AppColors.primary)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _alerts.isEmpty
                  ? const Center(child: Text('No notifications yet'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _alerts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final alert = _alerts[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(alert.alertType, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(alert.description, style: const TextStyle(color: AppColors.textSecondary)),
                                const SizedBox(height: 8),
                                Text(
                                  alert.timestamp,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
