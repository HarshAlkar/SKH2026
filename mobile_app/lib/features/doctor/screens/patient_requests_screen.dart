import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/call_launcher.dart';
import '../../../core/services/signaling_service.dart';
import '../../../providers/auth_provider.dart';
import '../../user/services/doctor_service.dart';
import '../../user/screens/call_screen.dart';
import '../services/doctor_appointment_service.dart';
import '../widgets/doctor_navigation_drawer.dart';
import 'patient_details_screen.dart';

class _RequestItem {
  final String id;
  final String kind; // appointment | consultation
  final String patientName;
  final String age;
  final String village;
  final String symptoms;
  final String priority;
  String status; // Pending | Accepted | Rejected
  final int? patientId;
  final int? patientUserId;
  final String callType;
  final DoctorAppointment? appointment;

  _RequestItem({
    required this.id,
    required this.kind,
    required this.patientName,
    required this.age,
    required this.village,
    required this.symptoms,
    required this.priority,
    required this.status,
    this.patientId,
    this.patientUserId,
    this.callType = 'VIDEO',
    this.appointment,
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
  int _bottomNavIndex = 0;
  final _appointmentService = DoctorAppointmentService();
  final _doctorService = DoctorService();
  final List<_RequestItem> _requests = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final appointments = await _appointmentService.getAppointments();
      final pendingConsults = await _doctorService.getPendingConsultations();
      final items = <_RequestItem>[];

      for (final a in appointments) {
        String uiStatus;
        switch (a.status.toUpperCase()) {
          case 'ACCEPTED':
            uiStatus = 'Accepted';
            break;
          case 'CANCELLED':
            uiStatus = 'Rejected';
            break;
          case 'COMPLETED':
            uiStatus = 'Accepted';
            break;
          default:
            uiStatus = 'Pending';
        }
        items.add(_RequestItem(
          id: 'apt-${a.id}',
          kind: 'appointment',
          patientName: a.patientName,
          age: a.age,
          village: a.village,
          symptoms: a.notes.isNotEmpty ? a.notes : a.historySummary,
          priority: a.type == DoctorConsultationType.video ? 'Video' : (a.type == DoctorConsultationType.audio ? 'Audio' : 'Offline'),
          status: uiStatus,
          patientId: a.patientId,
          patientUserId: a.patientUserId,
          callType: a.type == DoctorConsultationType.audio ? 'AUDIO' : 'VIDEO',
          appointment: a,
        ));
      }

      for (final c in pendingConsults) {
        items.add(_RequestItem(
          id: 'con-${c['id']}',
          kind: 'consultation',
          patientName: (c['patient_name'] ?? c['asha_name'] ?? 'Caller').toString(),
          age: '—',
          village: '—',
          symptoms: (c['notes'] ?? 'Incoming ${c['call_type'] ?? 'VIDEO'} consultation').toString(),
          priority: (c['is_emergency'] == true) ? 'Urgent' : 'General',
          status: 'Pending',
          patientId: c['patient'] is int ? c['patient'] as int : int.tryParse(c['patient']?.toString() ?? ''),
          patientUserId: c['patient_user_id'] is int
              ? c['patient_user_id'] as int
              : int.tryParse(c['patient_user_id']?.toString() ?? '') ??
                  (c['initiated_by'] is int
                      ? c['initiated_by'] as int
                      : int.tryParse(c['initiated_by']?.toString() ?? '')),
          callType: (c['call_type'] ?? 'VIDEO').toString().toUpperCase(),
        ));
      }

      if (!mounted) return;
      setState(() {
        _requests
          ..clear()
          ..addAll(items);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  bool get _isVerified {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    return user?.detail('verification_status', fallback: 'INCOMPLETE') == 'VERIFIED';
  }

  Future<void> _acceptRequest(_RequestItem request) async {
    if (!_isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You must complete your professional profile and be verified by admin before accepting requests.',
          ),
        ),
      );
      return;
    }

    try {
      if (request.kind == 'appointment' && request.appointment != null) {
        await _appointmentService.acceptAppointment(request.appointment!.id);
      } else if (request.kind == 'consultation') {
        final rawId = request.id.replaceFirst('con-', '');
        await _doctorService.acceptConsultation(rawId);
        SignalingService().emitAccept(
          rawId,
          callerUserId: request.patientUserId?.toString(),
        );
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CallScreen(
              consultationId: rawId,
              doctorName: request.patientName,
              isVideo: request.callType != 'AUDIO',
              isOfferer: false,
              peerUserId: request.patientUserId,
            ),
          ),
        );
        await _load();
        return;
      }

      setState(() => request.status = 'Accepted');

      final peerUserId = request.patientUserId;
      if (peerUserId == null || peerUserId <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Accepted. Open patient details to start a call when the patient is online.')),
        );
        if (request.appointment != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PatientDetailsScreen(patient: request.appointment!.toPatientData()),
            ),
          );
        }
        return;
      }

      final startCall = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Start consultation?'),
          content: Text('Call ${request.patientName} now?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Later')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Start Call')),
          ],
        ),
      );

      if (startCall == true && mounted) {
        await CallLauncher.start(
          context: context,
          peerName: request.patientName,
          receiverUserId: peerUserId.toString(),
          isVideo: request.callType != 'AUDIO',
          patientId: request.patientId,
        );
      } else if (request.appointment != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PatientDetailsScreen(patient: request.appointment!.toPatientData()),
          ),
        );
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not accept: $e')),
      );
    }
  }

  Future<void> _rejectRequest(_RequestItem request) async {
    if (!_isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be verified before rejecting requests.')),
      );
      return;
    }
    try {
      if (request.kind == 'appointment' && request.appointment != null) {
        await _appointmentService.rejectAppointment(request.appointment!.id);
      }
      setState(() => request.status = 'Rejected');
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not reject: $e')),
      );
    }
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
            icon: const Icon(Icons.refresh, color: textPrimary),
            onPressed: _load,
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
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRequestList('Pending'),
                      _buildRequestList('Accepted'),
                      _buildRequestList('Rejected'),
                    ],
                  ),
                ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildRequestList(String status) {
    final filteredRequests = _requests.where((r) => r.status == status).toList();

    if (filteredRequests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text(
              'No requests found.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: filteredRequests.length,
      itemBuilder: (context, index) => _buildPatientRequestCard(filteredRequests[index]),
    );
  }

  Widget _buildPatientRequestCard(_RequestItem request) {
    const primaryBlue = Color(0xFF2A7DE1);
    const textPrimary = Color(0xFF1F2937);
    const textSecondary = Color(0xFF6B7280);

    Color badgeBgColor;
    Color badgeTextColor;
    if (request.priority == 'Urgent') {
      badgeBgColor = const Color(0xFFFEE2E2);
      badgeTextColor = const Color(0xFFDC2626);
    } else if (request.priority == 'General' || request.priority == 'Video') {
      badgeBgColor = const Color(0xFFE0E7FF);
      badgeTextColor = primaryBlue;
    } else {
      badgeBgColor = const Color(0xFFFEF3C7);
      badgeTextColor = const Color(0xFFD97706);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFF1E293B),
                child: Icon(Icons.person, size: 30, color: Colors.white70),
              ),
              const SizedBox(width: 12),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.assignment_outlined, size: 18, color: textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.symptoms,
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (request.status == 'Pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => _acceptRequest(request),
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
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => _rejectRequest(request),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textPrimary,
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Reject Request',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
            color: Colors.black.withValues(alpha: 0.05),
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
          setState(() => _bottomNavIndex = index);
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
