import 'package:flutter/material.dart';
import 'package:hs053/core/widgets/common_appbar.dart';
import 'package:hs053/core/routes/app_routes.dart';
import 'package:hs053/features/asha_worker/widgets/asha_drawer.dart';
import 'package:hs053/shared/models/visit_model.dart';
import '../widgets/visit_card.dart';
import 'schedule_visit_screen.dart';
import 'package:hs053/core/services/api_service.dart';

class VillageVisitsScreen extends StatefulWidget {
  const VillageVisitsScreen({super.key});

  @override
  State<VillageVisitsScreen> createState() => _VillageVisitsScreenState();
}

class _VillageVisitsScreenState extends State<VillageVisitsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  
  final Color primaryColor = const Color(0xFF2F4DB6);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  List<VisitModel> _allVisits = [];
  List<VisitModel> _filteredVisits = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchVisits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchVisits() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.get('/asha-workers/visits/');
      final List<VisitModel> fetched = (response as List)
          .map((data) => VisitModel.fromJson(data))
          .toList();

      setState(() {
        _allVisits = fetched;
        _filteredVisits = fetched;
        _isLoading = false;
      });
      _filterVisits(_searchController.text);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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

  Future<void> _markVisitComplete(VisitModel visit) async {
    try {
      await _apiService.patch('/asha-workers/visits/${visit.id}/', body: {
        'status': 'COMPLETED',
      });
      
      // Update local state
      setState(() {
        int index = _allVisits.indexWhere((v) => v.id == visit.id);
        if (index != -1) {
          _allVisits[index] = _allVisits[index].copyWith(status: VisitStatus.completed);
          _filterVisits(_searchController.text);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Visit marked as completed"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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
          ).then((value) {
            if (value == true) {
              _fetchVisits();
            }
          });
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                              const SizedBox(height: 16),
                              Text("Error: $_error", textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchVisits,
                                child: const Text("Retry"),
                              )
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchVisits,
                          child: _filteredVisits.isEmpty
                              ? ListView(
                                  children: [
                                    const SizedBox(height: 100),
                                    const Center(
                                      child: Text(
                                        "No visits found.",
                                        style: TextStyle(color: Colors.grey, fontSize: 16),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _filteredVisits.length,
                                  itemBuilder: (context, index) {
                                    final visit = _filteredVisits[index];
                                    return VisitCard(
                                      visit: visit,
                                      onMarkComplete: () => _markVisitComplete(visit),
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
