import 'package:flutter/material.dart';
import '../models/health_record_model.dart';
import '../widgets/health_record_card.dart';
import '../../asha_worker/screens/update_health_screen.dart';
import '../../asha_worker/widgets/asha_sidebar.dart';
import '../../../core/sync/offline_api.dart';

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({super.key});

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final OfflineApi _api = OfflineApi.instance;

  List<HealthRecordModel> _allRecords = [];
  List<HealthRecordModel> _filteredRecords = [];
  bool _loading = true;
  String? _error;

  final Color primaryColor = const Color(0xFF2F4DB6);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _load();
  }

  RiskLevel _riskFrom(String raw) {
    switch (raw) {
      case 'highRisk':
        return RiskLevel.highRisk;
      case 'moderate':
        return RiskLevel.moderate;
      default:
        return RiskLevel.normal;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _api.get('/records/');
      final rows = response is List ? response : <dynamic>[];
      final records = <HealthRecordModel>[];
      for (final row in rows) {
        if (row is! Map) continue;
        final map = Map<String, dynamic>.from(row);
        records.add(
          HealthRecordModel(
            patientName: map['patientName']?.toString() ?? 'Patient',
            village: map['village']?.toString() ?? '',
            temperature: map['temperature']?.toString() ?? '--',
            bloodPressure: map['bloodPressure']?.toString() ?? '--',
            bloodSugar: map['bloodSugar']?.toString() ?? '--',
            weight: map['weight']?.toString() ?? '--',
            lastUpdated: map['lastUpdated']?.toString() ?? '',
            riskLevel: _riskFrom(map['riskLevel']?.toString() ?? ''),
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _allRecords = records;
        _filteredRecords = records;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load health records. Pull to retry.';
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterRecords(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredRecords = _allRecords;
      } else {
        _filteredRecords = _allRecords
            .where(
              (record) =>
                  record.patientName.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  record.village.toLowerCase().contains(query.toLowerCase()),
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
          "Health Records",
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
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UpdateHealthScreen()),
          );
          _load();
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Section
            Container(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterRecords,
                  decoration: InputDecoration(
                    hintText: 'Search patient records...',
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
            // Health Record List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_error!, textAlign: TextAlign.center),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _load,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: _filteredRecords.isEmpty
                              ? ListView(
                                  children: const [
                                    SizedBox(height: 120),
                                    Center(child: Text('No health records yet')),
                                  ],
                                )
                              : ListView.builder(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _filteredRecords.length,
                                  itemBuilder: (context, index) {
                                    return HealthRecordCard(
                                      record: _filteredRecords[index],
                                    );
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
