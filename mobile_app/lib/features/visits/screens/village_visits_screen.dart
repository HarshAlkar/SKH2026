import 'package:flutter/material.dart';
import '../../../core/widgets/common_appbar.dart';
import '../../../routes/app_routes.dart';
import '../../asha_worker/widgets/asha_drawer.dart';
import '../models/visit_model.dart';
import '../widgets/visit_card.dart';
import 'schedule_visit_screen.dart';

class VillageVisitsScreen extends StatefulWidget {
  const VillageVisitsScreen({super.key});

  @override
  State<VillageVisitsScreen> createState() => _VillageVisitsScreenState();
}

class _VillageVisitsScreenState extends State<VillageVisitsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Color primaryColor = const Color(0xFF2F4DB6);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  final List<VisitModel> _allVisits = [
    VisitModel(
      id: '1',
      patientName: 'Sita Devi',
      village: 'Rampur',
      visitTime: '10:30 AM',
      visitDate: DateTime.now(),
      status: VisitStatus.pending,
    ),
    VisitModel(
      id: '2',
      patientName: 'Ramesh Patil',
      village: 'Kaman',
      visitTime: '11:45 AM',
      visitDate: DateTime.now(),
      status: VisitStatus.completed,
    ),
    VisitModel(
      id: '3',
      patientName: 'Amit Shinde',
      village: 'Rampur',
      visitTime: '01:15 PM',
      visitDate: DateTime.now(),
      status: VisitStatus.pending,
    ),
    VisitModel(
      id: '4',
      patientName: 'Shanti Devi',
      village: 'Kaman',
      visitTime: '02:30 PM',
      visitDate: DateTime.now(),
      status: VisitStatus.missed,
    ),
    VisitModel(
      id: '5',
      patientName: 'Gopal Krishan',
      village: 'Vikhroli',
      visitTime: '04:00 PM',
      visitDate: DateTime.now(),
      status: VisitStatus.pending,
    ),
  ];

  List<VisitModel> _filteredVisits = [];

  @override
  void initState() {
    super.initState();
    _filteredVisits = List.from(_allVisits);
  }

  void _filterVisits(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredVisits = List.from(_allVisits);
      } else {
        _filteredVisits = _allVisits
            .where(
              (v) =>
                  v.patientName.toLowerCase().contains(query.toLowerCase()) ||
                  v.village.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int total = _allVisits.length;
    int completed = _allVisits
        .where((v) => v.status == VisitStatus.completed)
        .length;
    int pending = _allVisits
        .where((v) => v.status == VisitStatus.pending)
        .length;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: CommonAppBar(
        title: "Village Visits",
        actions: [
          IconButton(
            icon: const Icon(
              Icons.calendar_month_outlined,
              color: Colors.white,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AshaDrawer(currentRoute: AppRoutes.villageVisits),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ScheduleVisitScreen(),
            ),
          );
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Summary Banner
            Container(
              padding: const EdgeInsets.all(16),
              color: primaryColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem("Total", total.toString()),
                  _buildStatItem("Completed", completed.toString()),
                  _buildStatItem("Pending", pending.toString()),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
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
                  onChanged: _filterVisits,
                  decoration: InputDecoration(
                    hintText: 'Search patient or village...',
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

            // Visit List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredVisits.length,
                itemBuilder: (context, index) {
                  final visit = _filteredVisits[index];
                  return VisitCard(
                    visit: visit,
                    onMarkComplete: () {
                      setState(() {
                        int originalIndex = _allVisits.indexWhere(
                          (v) => v.id == visit.id,
                        );
                        if (originalIndex != -1) {
                          _allVisits[originalIndex] = _allVisits[originalIndex]
                              .copyWith(status: VisitStatus.completed);
                          // Re-filter to update UI
                          _filteredVisits[index] = _allVisits[originalIndex];
                        }
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Visit marked as completed"),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
