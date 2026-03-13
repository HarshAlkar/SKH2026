import 'package:flutter/material.dart';
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

  final List<AlertModel> _allAlerts = [
    AlertModel(
      patientName: 'Ramesh Patil',
      alertType: 'High Fever',
      description:
          'Temperature recorded at 103.5°F. Immediate intervention required as per protocol.',
      timestamp: '10 mins ago',
      severityLevel: AlertSeverity.urgent,
    ),
    AlertModel(
      patientName: 'Shanti Devi',
      alertType: 'Blood Pressure Alert',
      description:
          'BP reading 150/95 mmHg. Patient advised to rest and re-measure in 1 hour.',
      timestamp: '2 hours ago',
      severityLevel: AlertSeverity.moderate,
    ),
    AlertModel(
      patientName: 'Arjun Kumar',
      alertType: 'Follow-up',
      description:
          'Post-surgery recovery stable. All vitals within normal range.',
      timestamp: '5 hours ago',
      severityLevel: AlertSeverity.normal,
    ),
  ];

  List<AlertModel> _filteredAlerts = [];

  final Color primaryColor = const Color(0xFF2F4DB6);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _filteredAlerts = _allAlerts;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            icon: const CircleAvatar(
              backgroundColor: Colors.white24,
              radius: 16,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
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
          );
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

            // Alert List
            Expanded(
              child: ListView.builder(
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
          ],
        ),
      ),
    );
  }
}
