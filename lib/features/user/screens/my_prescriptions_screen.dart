import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/user_sidebar.dart';

class MyPrescriptionsScreen extends StatefulWidget {
  const MyPrescriptionsScreen({super.key});

  @override
  State<MyPrescriptionsScreen> createState() => _MyPrescriptionsScreenState();
}

class _MyPrescriptionsScreenState extends State<MyPrescriptionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            icon: const Icon(Icons.search, color: AppColors.primary),
            onPressed: () {},
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCurrentTab(),
          _buildPastRecordsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCurrentTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildPrescriptionCard(
          doctorName: 'Dr. Rajesh Kumar',
          specialty: 'MBBS, MD - General Physician',
          date: 'Today',
          isPast: false,
          medicines: [
            {'name': 'Paracetamol 500mg', 'dosage': '1-0-1 (After Meals) • 5 Days'},
            {'name': 'Amoxicillin 250mg', 'dosage': '1-1-1 (After Meals) • 3 Days'},
            {'name': 'Cetirizine 10mg', 'dosage': '0-0-1 (Before Sleep) • 5 Days'},
          ],
        ),
        const SizedBox(height: 40),
        _buildEndOfList(),
      ],
    );
  }

  Widget _buildPastRecordsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildPrescriptionCard(
          doctorName: 'Dr. Anjali Verma',
          specialty: 'Dermatologist',
          date: '12 Oct 2023',
          isPast: true,
          medicines: [
            {'name': 'Betadine Ointment', 'dosage': 'Apply 2 times daily'},
            {'name': 'Allegra 120mg', 'dosage': '1-0-0 (Morning)'},
          ],
        ),
        const SizedBox(height: 40),
        _buildEndOfList(),
      ],
    );
  }

  Widget _buildPrescriptionCard({
    required String doctorName,
    required String specialty,
    required String date,
    required List<Map<String, String>> medicines,
    required bool isPast,
  }) {
    return Container(
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
                  color: AppColors.lightBlue,
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
                      doctorName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      specialty,
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
                  date,
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
                'Medicines (${medicines.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...medicines.map((med) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med['name']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      med['dosage']!,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
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
                        onPressed: () {},
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

  Widget _buildEndOfList() {
    return Column(
      children: [
        Icon(Icons.inventory_2_outlined, color: Colors.grey.shade300, size: 48),
        const SizedBox(height: 12),
        const Text(
          'End of list',
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
