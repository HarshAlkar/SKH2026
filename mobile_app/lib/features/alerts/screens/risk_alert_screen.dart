import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../asha_worker/widgets/asha_sidebar.dart';
import '../models/alert_model.dart';
import '../widgets/alert_card.dart';
import 'create_alert_screen.dart';

class RiskAlertScreen extends StatefulWidget {
  const RiskAlertScreen({super.key});

  @override
  State<RiskAlertScreen> createState() => _RiskAlertScreenState();
}

class _RiskAlertScreenState extends State<RiskAlertScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _api = ApiService();

  List<AlertModel> _allAlerts = [];
  List<AlertModel> _filteredAlerts = [];
  bool _loading = true;
  String? _error;

  final Color primaryColor = const Color(0xFF2F4DB6);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _api.get('/alerts/notifications/');
      final rows = response is List ? response : <dynamic>[];
      final alerts = rows
          .whereType<Map>()
          .map((row) => AlertModel.fromNotification(Map<String, dynamic>.from(row)))
          .toList();
      if (!mounted) return;
      setState(() {
        _allAlerts = alerts;
        _loading = false;
      });
      _filterAlerts(_searchController.text);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load alerts';
        _loading = false;
      });
    }
  }

  void _filterAlerts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredAlerts = _allAlerts;
      } else {
        final q = query.toLowerCase();
        _filteredAlerts = _allAlerts
            .where(
              (alert) =>
                  alert.patientName.toLowerCase().contains(q) ||
                  alert.alertType.toLowerCase().contains(q),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: const AshaSidebar(),
      appBar: AppBar(
        title: const Text(
          "Health Risk Alerts",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAlerts,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreateAlertScreen()),
          );
          if (created == true) _loadAlerts();
        },
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: backgroundColor,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterAlerts,
                  decoration: InputDecoration(
                    hintText: 'Search patients...',
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
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadAlerts, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_filteredAlerts.isEmpty) {
      return Center(
        child: Text(
          'No risk alerts yet.\nHigh/Critical symptom checks appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600], height: 1.5),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAlerts,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _filteredAlerts.length,
        itemBuilder: (context, index) {
          return AlertCard(alert: _filteredAlerts[index]);
        },
      ),
    );
  }
}
