import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../asha_worker/widgets/asha_sidebar.dart';
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
  final ApiService _api = ApiService();
  final Color primaryColor = const Color(0xFF2F4DB6);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  List<VisitModel> _allVisits = [];
  List<VisitModel> _filteredVisits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  VisitStatus _statusFrom(String raw) {
    switch (raw.toUpperCase()) {
      case 'COMPLETED':
        return VisitStatus.completed;
      case 'MISSED':
        return VisitStatus.missed;
      default:
        return VisitStatus.pending;
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await _api.get('/asha/visits/');
      final rows = response is List ? response : <dynamic>[];
      final visits = <VisitModel>[];
      for (final row in rows) {
        if (row is! Map) continue;
        final map = Map<String, dynamic>.from(row);
        visits.add(
          VisitModel(
            id: map['id'].toString(),
            patientName: map['patient_name']?.toString() ?? 'Patient',
            village: map['village']?.toString() ?? '',
            visitTime: '${map['visit_date'] ?? ''} ${map['visit_time'] ?? ''}'.trim(),
            status: _statusFrom(map['status']?.toString() ?? ''),
            notes: map['notes']?.toString() ?? '',
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _allVisits = visits;
        _filterVisits(_searchController.text);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filterVisits(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredVisits = List.from(_allVisits);
      } else {
        final q = query.toLowerCase();
        _filteredVisits = _allVisits
            .where(
              (v) =>
                  v.patientName.toLowerCase().contains(q) ||
                  v.village.toLowerCase().contains(q),
            )
            .toList();
      }
    });
  }

  Future<void> _markComplete(VisitModel visit) async {
    try {
      await _api.patch('/asha/visits/${visit.id}/', body: {'status': 'COMPLETED'});
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update visit: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int total = _allVisits.length;
    int completed = _allVisits.where((v) => v.status == VisitStatus.completed).length;
    int pending = _allVisits.where((v) => v.status == VisitStatus.pending).length;

    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: const AshaSidebar(),
      appBar: AppBar(
        title: const Text(
          'Village Visits',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const ScheduleVisitScreen()),
          );
          if (created == true) _load();
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: primaryColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Total', total.toString()),
                        _buildStatItem('Completed', completed.toString()),
                        _buildStatItem('Pending', pending.toString()),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterVisits,
                      decoration: InputDecoration(
                        hintText: 'Search patient or village...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _filteredVisits.isEmpty
                        ? const Center(child: Text('No visits scheduled yet'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredVisits.length,
                            itemBuilder: (context, index) {
                              final visit = _filteredVisits[index];
                              return VisitCard(
                                visit: visit,
                                onMarkComplete: () => _markComplete(visit),
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
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
