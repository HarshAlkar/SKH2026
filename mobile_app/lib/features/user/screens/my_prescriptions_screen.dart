import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../widgets/user_sidebar.dart';
import '../../../core/sync/offline_api.dart';
import '../../../core/services/pdf_service.dart';
import 'package:intl/intl.dart';

class MyPrescriptionsScreen extends StatefulWidget {
  const MyPrescriptionsScreen({super.key});

  @override
  State<MyPrescriptionsScreen> createState() => _MyPrescriptionsScreenState();
}

class _MyPrescriptionsScreenState extends State<MyPrescriptionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OfflineApi _api = OfflineApi.instance;
  bool _isLoading = true;
  String? _error;
  List<dynamic> _prescriptions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchPrescriptions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPrescriptions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _api.get('/prescriptions/user/');
      setState(() {
        _prescriptions = data is List ? data : [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching prescriptions: $e');
      setState(() {
        _error = 'Could not load prescriptions';
        _isLoading = false;
      });
    }
  }

  DateTime _issuedAt(dynamic p) {
    if (p is! Map) return DateTime.now();
    final raw = p['issued_at'] ?? p['created_at'] ?? '';
    return DateTime.tryParse(raw.toString()) ?? DateTime.now();
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
          'My Prescriptions',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _fetchPrescriptions,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Current'),
            Tab(text: 'Past Records'),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Text(_error!, style: const TextStyle(color: Colors.grey)))
            : TabBarView(
            controller: _tabController,
            children: [
              _buildCurrentTab(),
              _buildPastRecordsTab(),
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.consultDoctor),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.medical_services_outlined, color: Colors.white),
        label: const Text('Consult Doctor', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildCurrentTab() {
    final current = _prescriptions.where((p) {
      return DateTime.now().difference(_issuedAt(p)).inDays < 30;
    }).toList();

    if (current.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No active prescriptions found", style: TextStyle(color: Colors.grey)),
        ],
      ));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: current.length,
      itemBuilder: (context, index) => _buildPrescriptionFromData(current[index]),
    );
  }

  Widget _buildPastRecordsTab() {
    final past = _prescriptions.where((p) {
      return DateTime.now().difference(_issuedAt(p)).inDays >= 30;
    }).toList();

    if (past.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No past records found", style: TextStyle(color: Colors.grey)),
        ],
      ));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: past.length,
      itemBuilder: (context, index) => _buildPrescriptionFromData(past[index], isPast: true),
    );
  }

  Widget _buildPrescriptionFromData(dynamic data, {bool isPast = false}) {
    final date = _issuedAt(data);
    final formattedDate = DateFormat('dd MMM yyyy').format(date);
    
    // Medications parsing: Medications is a string of comma separated values usually
    List<String> meds = (data['medications'] ?? "").toString().split('\n').where((m) => m.trim().isNotEmpty).toList();
    if (meds.isEmpty) meds = (data['medications'] ?? "").toString().split(',').where((m) => m.trim().isNotEmpty).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_outline, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['doctor_name'] ?? 'Unknown Doctor',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      data['notes'] ?? 'Consultation Record',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPast ? Colors.grey.shade100 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  formattedDate,
                  style: TextStyle(
                    color: isPast ? Colors.grey.shade600 : AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.medication_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Medicines (${meds.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...meds.map((med) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        med.trim(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          if (data['diagnosis'] != null && data['diagnosis'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              "Diagnosis: ${data['diagnosis']}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final path = await PdfService.generatePrescriptionPdf(
                        Map<String, dynamic>.from(data),
                        context: context,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Saved to $path')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Download failed: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Download'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: isPast
                    ? OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.history, size: 18),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: BorderSide(color: Colors.grey.shade200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/medicine-tracker'),
                        icon: const Icon(Icons.alarm_add, size: 18),
                        label: const Text('Add Tracker'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
