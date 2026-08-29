import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import 'patient_details_screen.dart';
import '../widgets/doctor_navigation_drawer.dart';

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

  final List<PatientRequest> _requests = [
    PatientRequest(
      id: "1",
      patientName: "Ramesh Patil",
      age: 45,
      village: "Kaman",
      symptoms: "Fever, Cough, Mild Headache",
      priority: "Urgent",
    ),
    PatientRequest(
      id: "2",
      patientName: "Sunita Deshmukh",
      age: 28,
      village: "Pelhar",
      symptoms: "Back Pain, Fatigue",
      priority: "General",
    ),
    PatientRequest(
      id: "3",
      patientName: "Lata Bai",
      age: 62,
      village: "Vasai",
      symptoms: "Knee Swelling, Difficulty Walking",
      priority: "Follow-up",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _acceptRequest(String id) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final isVerified = user?.detail('verification_status', fallback: 'INCOMPLETE') == 'VERIFIED';
    
    if (!isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must complete your professional profile and be verified by admin before accepting requests.')),
      );
      return;
    }

    setState(() {
      final index = _requests.indexWhere((r) => r.id == id);
      if (index != -1) {
        _requests[index].status = 'Accepted';
      }
    });
    // Navigation to patient details screen
    final request = _requests.firstWhere((r) => r.id == id);
    final patientData = PatientData(
      name: request.patientName,
      age: request.age.toString(),
      gender: 'Not set',
      village: request.village,
      bloodType: 'Not set',
      chronicConditions: request.symptoms,
      pastSurgeries: 'Not recorded',
      allergies: 'Not recorded',
      symptoms: const [],
      aiInsights: 'Priority: ${request.priority}. Review patient profile and schedule consultation.',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailsScreen(patient: patientData),
      ),
    );
  }

  void _rejectRequest(String id) {
    setState(() {
      final index = _requests.indexWhere((r) => r.id == id);
      if (index != -1) {
        _requests[index].status = 'Rejected';
      }
    });
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestList('Pending'),
          _buildRequestList('Accepted'),
          _buildRequestList('Rejected'),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildRequestList(String status) {
    final filteredRequests = _requests
        .where((r) => r.status == status)
        .toList();

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
        return _buildPatientRequestCard(filteredRequests[index]);
      },
    );
  }

  Widget _buildPatientRequestCard(PatientRequest request) {
    const primaryBlue = Color(0xFF2A7DE1);
    const textPrimary = Color(0xFF1F2937);
    const textSecondary = Color(0xFF6B7280);

    Color badgeBgColor;
    Color badgeTextColor;

    if (request.priority == 'Urgent') {
      badgeBgColor = const Color(0xFFE0E7FF); // Light blue/indigo
      badgeTextColor = primaryBlue;
    } else if (request.priority == 'General') {
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
                      request.patientName,
                      style: const TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Age: ${request.age} · Village: ${request.village}',
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
                  request.priority,
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
                    'Symptoms: ${request.symptoms}',
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

          if (request.status == 'Pending') ...[
            const SizedBox(height: 16),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => _acceptRequest(request.id),
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
                      onPressed: () => _rejectRequest(request.id),
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
        onTap: (index) {
          if (index == 0 && Navigator.canPop(context)) {
            Navigator.pop(context);
            return;
          }
          setState(() {
            _bottomNavIndex = index;
          });
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
