import 'package:flutter/material.dart';
import '../models/health_record_model.dart';
import '../widgets/health_record_card.dart';

import '../../asha_worker/widgets/asha_drawer.dart';

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({super.key});

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<HealthRecordModel> _allRecords = [
    HealthRecordModel(
      patientName: 'Ramesh Patil',
      village: 'Kaman',
      temperature: '98.6',
      bloodPressure: '120/80',
      bloodSugar: '100',
      weight: '65',
      lastUpdated: 'Today',
      riskLevel: RiskLevel.normal,
    ),
    HealthRecordModel(
      patientName: 'Shanti Devi',
      village: 'Kaman',
      temperature: '101.2',
      bloodPressure: '150/95',
      bloodSugar: '140',
      weight: '62',
      lastUpdated: 'Yesterday',
      riskLevel: RiskLevel.moderate,
    ),
    HealthRecordModel(
      patientName: 'Amit Shinde',
      village: 'Rampur',
      temperature: '103.5',
      bloodPressure: '160/100',
      bloodSugar: '180',
      weight: '70',
      lastUpdated: '2 days ago',
      riskLevel: RiskLevel.highRisk,
    ),
    HealthRecordModel(
      patientName: 'Sita Devi',
      village: 'Rampur',
      temperature: '98.4',
      bloodPressure: '115/75',
      bloodSugar: '95',
      weight: '58',
      lastUpdated: '1 week ago',
      riskLevel: RiskLevel.normal,
    ),
  ];

  List<HealthRecordModel> _filteredRecords = [];

  final Color primaryColor = const Color(0xFF2F4DB6);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _filteredRecords = _allRecords;
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
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: const [SizedBox(width: 8)],
      ),

      drawer: const AshaDrawer(),
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
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredRecords.length,
                itemBuilder: (context, index) {
                  return HealthRecordCard(record: _filteredRecords[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
