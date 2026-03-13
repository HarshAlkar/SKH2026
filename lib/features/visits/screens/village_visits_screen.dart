import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/visit_model.dart';
import '../widgets/visit_card.dart';
import 'schedule_visit_screen.dart';
import '../../asha_worker/widgets/asha_drawer.dart';

class VillageVisitsScreen extends StatefulWidget {
  const VillageVisitsScreen({super.key});

  @override
  State<VillageVisitsScreen> createState() => _VillageVisitsScreenState();
}

class _VillageVisitsScreenState extends State<VillageVisitsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Color primaryColor = const Color(0xFF2F4DB6);
  final Color backgroundColor = const Color(0xFFF5F7FA);
  DateTime? _selectedDate;

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
      visitDate: DateTime.now().add(const Duration(days: 1)),
      status: VisitStatus.pending,
    ),
    VisitModel(
      id: '4',
      patientName: 'Shanti Devi',
      village: 'Kaman',
      visitTime: '02:30 PM',
      visitDate: DateTime.now().add(const Duration(days: 1)),
      status: VisitStatus.missed,
    ),
    VisitModel(
      id: '5',
      patientName: 'Gopal Krishan',
      village: 'Vikhroli',
      visitTime: '04:00 PM',
      visitDate: DateTime.now().add(const Duration(days: 2)),
      status: VisitStatus.pending,
    ),
  ];

  List<VisitModel> _filteredVisits = [];

  @override
  void initState() {
    super.initState();
    _filteredVisits = List.from(_allVisits);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _applyFilters();
      });
    }
  }

  void _filterVisits(String query) {
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredVisits = _allVisits.where((v) {
        final matchesQuery =
            v.patientName.toLowerCase().contains(query) ||
            v.village.toLowerCase().contains(query);

        bool matchesDate = true;
        if (_selectedDate != null) {
          matchesDate =
              v.visitDate.year == _selectedDate!.year &&
              v.visitDate.month == _selectedDate!.month &&
              v.visitDate.day == _selectedDate!.day;
        }

        return matchesQuery && matchesDate;
      }).toList();
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
      appBar: AppBar(
        title: const Text(
          "Village Visits",
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
        actions: [
          IconButton(
            icon: const Icon(
              Icons.calendar_month_outlined,
              color: Colors.white,
            ),
            onPressed: _selectDate,
          ),
          const SizedBox(width: 8),
        ],
      ),
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
      drawer: const AshaDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Summary Card Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      "Today's Visits",
                      total.toString(),
                      primaryColor,
                    ),
                    _buildVerticalDivider(),
                    _buildStatItem(
                      "Completed",
                      completed.toString(),
                      Colors.green,
                    ),
                    _buildVerticalDivider(),
                    _buildStatItem(
                      "Pending",
                      pending.toString(),
                      Colors.orange,
                    ),
                  ],
                ),
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
            // Selected Date Indicator
            if (_selectedDate != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_available,
                      size: 16,
                      color: Color(0xFF2F4DB6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Selected Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate!)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedDate = null;
                          _applyFilters();
                        });
                      },
                      child: const Text(
                        "Clear Filter",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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

  Widget _buildVerticalDivider() {
    return Container(height: 30, width: 1, color: Colors.grey.withOpacity(0.2));
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
