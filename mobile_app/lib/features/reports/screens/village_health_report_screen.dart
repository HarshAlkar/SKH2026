import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../asha_worker/widgets/asha_sidebar.dart';
import '../widgets/stat_card.dart';

class VillageHealthReportScreen extends StatefulWidget {
  const VillageHealthReportScreen({super.key});

  @override
  State<VillageHealthReportScreen> createState() =>
      _VillageHealthReportScreenState();
}

class _VillageHealthReportScreenState extends State<VillageHealthReportScreen> {
  final Color primaryColor = const Color(0xFF2F4DB6);
  final Color backgroundColor = const Color(0xFFF5F7FA);
  final ApiService _api = ApiService();

  bool _loading = true;
  String _village = 'Village';
  int _totalPatients = 0;
  int _totalAlerts = 0;
  int _highRisk = 0;
  List<Map<String, dynamic>> _diseases = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final summary = await _api.get('/alerts/notifications/village-summary/');
      if (!mounted) return;
      final diseases = <Map<String, dynamic>>[];
      final raw = summary is Map ? summary['diseases'] : null;
      if (raw is List) {
        for (final row in raw) {
          if (row is Map) diseases.add(Map<String, dynamic>.from(row));
        }
      }
      setState(() {
        _village = (summary is Map ? summary['village'] : null)?.toString() ?? 'Village';
        _totalPatients = _asInt(summary is Map ? summary['total_patients'] : 0);
        _totalAlerts = _asInt(summary is Map ? summary['total_alerts'] : 0);
        _highRisk = _asInt(summary is Map ? summary['high_risk'] : 0);
        _diseases = diseases;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: const AshaSidebar(),
      appBar: AppBar(
        title: const Text(
          "Village Health Report",
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
            onPressed: _load,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(24),
                          ),
                        ),
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          bottom: 24,
                          top: 4,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _village,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Text(
                              "Live counts",
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: StatCard(
                                    icon: Icons.people_outline,
                                    label: "PATIENTS",
                                    value: "$_totalPatients",
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: StatCard(
                                    icon: Icons.notifications_outlined,
                                    label: "ALERTS",
                                    value: "$_totalAlerts",
                                    iconColor: Colors.orange,
                                    iconBackgroundColor:
                                        Colors.orange.withValues(alpha: 0.1),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: StatCard(
                                    icon: Icons.show_chart,
                                    label: "HIGH RISK",
                                    value: "$_highRisk",
                                    iconColor: Colors.redAccent,
                                    iconBackgroundColor:
                                        Colors.redAccent.withValues(alpha: 0.1),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildSectionContainer(
                              title: "Disease distribution (from alerts)",
                              child: _diseases.isEmpty
                                  ? Text(
                                      'No AI or manual alerts yet for this village.',
                                      style: TextStyle(color: Colors.grey[600]),
                                    )
                                  : Column(
                                      children: _diseases.map((row) {
                                        final name = row['name']?.toString() ?? 'Unknown';
                                        final count = row['count'] ?? 0;
                                        final maxCount = _diseases
                                            .map((d) => (d['count'] as num?)?.toDouble() ?? 0)
                                            .fold<double>(1, (a, b) => a > b ? a : b);
                                        final ratio = ((count as num).toDouble()) / maxCount;
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(child: Text(name)),
                                                  Text(
                                                    '$count',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              LinearProgressIndicator(
                                                value: ratio.clamp(0.05, 1),
                                                minHeight: 8,
                                                borderRadius: BorderRadius.circular(8),
                                                color: primaryColor,
                                                backgroundColor: const Color(0xFFE8F1FF),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
