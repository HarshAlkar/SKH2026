import 'package:flutter/material.dart';
import '../../user/services/doctor_service.dart';
import 'patient_details_screen.dart';
import '../widgets/doctor_navigation_drawer.dart';
import 'my_patients_screen.dart';
import 'upcoming_consultations_screen.dart';
import 'doctor_profile_screen.dart';
import 'doctor_dashboard.dart';

class PatientRequest {
  final String id;
  final String patientName;
  final int age;
  final String village;
  final String symptoms;
  final String priority; // Urgent, General, Follow-up
  String status; // Pending, Accepted, Rejected

  PatientRequest({
    required this.id,
    required this.patientName,
    required this.age,
    required this.village,
    required this.symptoms,
    required this.priority,
    this.status = 'Pending',
  });
}

class PatientRequestsScreen extends StatefulWidget {
  const PatientRequestsScreen({super.key});

  @override
  State<PatientRequestsScreen> createState() => _PatientRequestsScreenState();
}

class _PatientRequestsScreenState extends State<PatientRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _bottomNavIndex = 0; // Requests is index 0
  
  final DoctorService _doctorService = DoctorService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _acceptedRequests = [];
  List<Map<String, dynamic>> _rejectedRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _fetchAllRequests();
      }
    });
    _fetchAllRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllRequests() async {
    setState(() => _isLoading = true);
    
    final pending = await _doctorService.getPendingConsultations();
    final accepted = await _doctorService.getAcceptedConsultations();
    final rejected = await _doctorService.getRejectedConsultations();
    
    if (mounted) {
      setState(() {
        _pendingRequests = pending;
        _acceptedRequests = accepted;
        _rejectedRequests = rejected;
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptRequest(int id) async {
    setState(() => _isLoading = true);
    final success = await _doctorService.acceptConsultation(id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Consultation accepted successfully.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to accept consultation.')));
    }
    await _fetchAllRequests();
  }

  Future<void> _rejectRequest(int id) async {
    setState(() => _isLoading = true);
    final success = await _doctorService.rejectConsultation(id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Consultation rejected.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to reject consultation.')));
    }
    await _fetchAllRequests();
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2A7DE1);
    const textPrimary = Color(0xFF1F2937);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Patient Requests',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: textPrimary),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: primaryBlue,
              unselectedLabelColor: const Color(0xFF94A3B8),
              indicatorColor: primaryBlue,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Pending'),
                Tab(text: 'Accepted'),
                Tab(text: 'Rejected'),
              ],
            ),
          ),
        ),
      ),
      drawer: const DoctorNavigationDrawer(activeRoute: 'Patient Requests'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? 600 : constraints.maxWidth,
              ),
              child: PopScope(
                canPop: false,
                onPopInvoked: (didPop) {
                  if (didPop) return;
                  Navigator.pushReplacementNamed(context, '/doctor_dashboard');
                },
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRequestList('Pending'),
                    _buildRequestList('Accepted'),
                    _buildRequestList('Rejected'),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildRequestList(String status) {
    List<Map<String, dynamic>> filteredRequests;
    if (status == 'Pending') {
      filteredRequests = _pendingRequests;
    } else if (status == 'Accepted') {
      filteredRequests = _acceptedRequests;
    } else {
      filteredRequests = _rejectedRequests;
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredRequests.isEmpty) {
      return const Center(
        child: Text(
          'No requests found.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: filteredRequests.length,
      itemBuilder: (context, index) {
        return _buildPatientRequestCard(filteredRequests[index], status);
      },
    );
  }

  Widget _buildPatientRequestCard(Map<String, dynamic> request, String currentStatus) {
    const primaryBlue = Color(0xFF2A7DE1);
    const textPrimary = Color(0xFF1F2937);
    const textSecondary = Color(0xFF6B7280);

    final patientName = request['patient_name'] ?? 'Unknown';
    final age = request['patient_age'] ?? '--';
    final village = request['patient_village'] ?? 'Unknown';
    final symptoms = request['recent_symptoms'] ?? 'None reported';
    
    // Determine priority (could be from backend in future)
    String priority = "General";
    if (symptoms.toString().toLowerCase().contains('fever') ||
        symptoms.toString().toLowerCase().contains('pain')) {
      priority = "Urgent";
    }

    Color badgeBgColor;
    Color badgeTextColor;

    if (priority == 'Urgent') {
      badgeBgColor = const Color(0xFFE0E7FF); // Light blue/indigo
      badgeTextColor = primaryBlue;
    } else if (priority == 'General') {
      badgeBgColor = const Color(0xFFD1FAE5); // Light green
      badgeTextColor = const Color(0xFF059669); // Dark green
    } else {
      badgeBgColor = const Color(0xFFFEF3C7); // Light yellow
      badgeTextColor = const Color(0xFFD97706); // Amber
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Info, Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF1E293B),
                child: const Icon(
                  Icons.person,
                  size: 30,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 12),
              // Name and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: const TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Age: $age · Village: $village',
                      style: const TextStyle(
                        color: textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Symptoms container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.assignment_outlined,
                  size: 18,
                  color: textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Symptoms: $symptoms',
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (currentStatus == 'Pending') ...[
            const SizedBox(height: 16),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => _acceptRequest(request['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Accept Consultation',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => _rejectRequest(request['id']),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textPrimary,
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Reject Request',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) async {
          if (index == _bottomNavIndex) return;
          
          if (index == 0) {
            // Home - goes back to Dashboard
            Navigator.pushReplacementNamed(context, '/doctor_dashboard');
            return;
          }
          
          setState(() {
            _bottomNavIndex = index;
          });

          if (index == 1) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyPatientsScreen()),
            );
          } else if (index == 2) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UpcomingConsultationsScreen()),
            );
          } else if (index == 3) {
            // Use push so back button returns here
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DoctorProfileScreen()),
            );
          }
          
          if (mounted) {
            setState(() {
              _bottomNavIndex = 0; // 'REQUESTS' is at index 0 in this bar? Wait.
            });
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2A7DE1),
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedFontSize: 10,
        unselectedFontSize: 10,
        showUnselectedLabels: true,
        backgroundColor: Colors.white,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.request_page_outlined),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.request_page),
            ),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.people_alt_outlined),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.people),
            ),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.calendar_month_outlined),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.calendar_month),
            ),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.person_outline),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.person),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
