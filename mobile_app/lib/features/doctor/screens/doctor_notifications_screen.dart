import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/call_launcher.dart';
import '../../../core/services/signaling_service.dart';
import '../../../providers/auth_provider.dart';
import '../../user/services/doctor_service.dart';
import '../../user/screens/call_screen.dart';
import '../services/doctor_appointment_service.dart';
import 'asha_workers_screen.dart';
import 'patient_details_screen.dart';

class DoctorNotificationsScreen extends StatefulWidget {
  const DoctorNotificationsScreen({super.key});

  @override
  State<DoctorNotificationsScreen> createState() => _DoctorNotificationsScreenState();
}

class _DoctorNotificationsScreenState extends State<DoctorNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _appointmentService = DoctorAppointmentService();
  final _doctorService = DoctorService();
  bool _loading = true;
  List<DoctorAppointment> _pendingAppointments = [];
  List<Map<String, dynamic>> _pendingConsults = [];

  final Color primaryBlue = const Color(0xFF2A7DE1);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);

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
    setState(() => _loading = true);
    try {
      final appointments = await _appointmentService.getAppointments(status: 'SCHEDULED');
      final pending = await _doctorService.getPendingConsultations();
      if (!mounted) return;
      setState(() {
        _pendingAppointments = appointments;
        _pendingConsults = pending;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _isVerified {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    return user?.detail('verification_status', fallback: 'INCOMPLETE') == 'VERIFIED';
  }

  Future<void> _acceptAppointment(DoctorAppointment appointment) async {
    if (!_isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete verification before accepting requests.')),
      );
      return;
    }
    try {
      await _appointmentService.acceptAppointment(appointment.id);
      final peerUserId = appointment.patientUserId;
      if (peerUserId != null && peerUserId > 0 && mounted) {
        final start = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Start call?'),
            content: Text('Call ${appointment.patientName} now?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Later')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Call')),
            ],
          ),
        );
        if (start == true && mounted) {
          await CallLauncher.start(
            context: context,
            peerName: appointment.patientName,
            receiverUserId: peerUserId.toString(),
            isVideo: appointment.type != DoctorConsultationType.audio,
            patientId: appointment.patientId,
            doctorId: appointment.doctorId,
          );
        } else if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PatientDetailsScreen(patient: appointment.toPatientData()),
            ),
          );
        }
      } else if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PatientDetailsScreen(patient: appointment.toPatientData()),
          ),
        );
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Accept failed: $e')));
    }
  }

  Future<void> _declineAppointment(DoctorAppointment appointment) async {
    if (!_isVerified) return;
    final ok = await _appointmentService.rejectAppointment(appointment.id);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request declined')));
      await _load();
    }
  }

  Future<void> _acceptConsultation(Map<String, dynamic> c) async {
    if (!_isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete verification before accepting requests.')),
      );
      return;
    }
    final id = c['id']?.toString();
    if (id == null) return;
    try {
      await _doctorService.acceptConsultation(id);
      final peerUserId = c['patient_user_id'] ?? c['initiated_by'] ?? c['asha_user_id'];
      final peerId = int.tryParse(peerUserId?.toString() ?? '');
      final name = (c['patient_name'] ?? c['asha_name'] ?? 'Caller').toString();
      final isVideo = (c['call_type'] ?? 'VIDEO').toString().toUpperCase() != 'AUDIO';
      if (!mounted) return;
      SignalingService().emitAccept(id, callerUserId: peerId?.toString());
      // Join existing consultation room as answerer (do not create a new consult).
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
            consultationId: id,
            doctorName: name,
            isVideo: isVideo,
            isOfferer: false,
            peerUserId: peerId,
          ),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Accept failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: textPrimary),
            onPressed: _load,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryBlue,
          unselectedLabelColor: textSecondary,
          indicatorColor: primaryBlue,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Requests'),
            Tab(text: 'Alerts'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsList(includeHeader: true),
                _buildRequestsList(includeHeader: false),
                _buildAlertsTab(),
              ],
            ),
    );
  }

  Widget _buildRequestsList({required bool includeHeader}) {
    final hasItems = _pendingAppointments.isNotEmpty || _pendingConsults.isNotEmpty;
    if (!hasItems) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text('No pending requests', style: TextStyle(color: Color(0xFF9CA3AF)))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        children: [
          if (includeHeader) _buildSectionHeader('PENDING REQUESTS'),
          ..._pendingAppointments.map((a) {
            return NotificationCard(
              iconContent: _buildIconContainer(
                icon: Icons.medical_services_outlined,
                color: primaryBlue,
                bgColor: const Color(0xFFE8F1FF),
              ),
              title: 'Appointment request',
              message:
                  '${a.patientName} booked ${a.type.name} for ${a.rawDate} at ${a.formattedTime}. ${a.notes}',
              time: a.formattedTime,
              hasUnreadDot: true,
              unreadDotColor: primaryBlue,
              actionButtons: [
                _buildAcceptButton(() => _acceptAppointment(a)),
                const SizedBox(width: 12),
                _buildDeclineButton(() => _declineAppointment(a)),
              ],
            );
          }),
          ..._pendingConsults.map((c) {
            final name = (c['patient_name'] ?? c['asha_name'] ?? 'Caller').toString();
            final callType = (c['call_type'] ?? 'VIDEO').toString();
            return NotificationCard(
              iconContent: _buildIconContainer(
                icon: Icons.videocam_outlined,
                color: primaryBlue,
                bgColor: const Color(0xFFE8F1FF),
              ),
              title: 'Live consultation request',
              message: '$name requested a $callType consultation.',
              time: 'Now',
              hasUnreadDot: true,
              unreadDotColor: primaryBlue,
              actionButtons: [
                _buildAcceptButton(() => _acceptConsultation(c)),
                const SizedBox(width: 12),
                _buildDeclineButton(() async {
                  // Decline pending consult: no dedicated reject API; refresh UI.
                  setState(() => _pendingConsults.remove(c));
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAlertsTab() {
    return ListView(
      children: [
        _buildSectionHeader('QUICK ACTIONS'),
        NotificationCard(
          iconContent: _buildIconContainer(
            icon: Icons.emergency,
            color: const Color(0xFFEF4444),
            bgColor: const Color(0xFFFEE2E2),
          ),
          title: 'Contact ASHA workers',
          titleColor: const Color(0xFFDC2626),
          message: 'Reach village ASHA workers for emergency coordination.',
          time: '',
          backgroundColor: const Color(0xFFFFE9E9),
          actionButtons: [_buildEmergencyButton()],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildIconContainer({
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
      child: Center(child: Icon(icon, color: color, size: 24)),
    );
  }

  Widget _buildAcceptButton(VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        minimumSize: const Size(0, 36),
      ),
      onPressed: onPressed,
      child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildDeclineButton(VoidCallback onPressed) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF6B7280),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        minimumSize: const Size(0, 36),
      ),
      onPressed: onPressed,
      child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildEmergencyButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        minimumSize: const Size(0, 36),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DoctorAshaWorkersScreen()),
        );
      },
      icon: const Icon(Icons.phone, size: 16),
      label: const Text('Call ASHA Worker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final Widget iconContent;
  final String title;
  final String message;
  final String time;
  final Color? backgroundColor;
  final Color? titleColor;
  final bool hasUnreadDot;
  final Color? unreadDotColor;
  final List<Widget>? actionButtons;
  final VoidCallback? onTap;

  const NotificationCard({
    super.key,
    required this.iconContent,
    required this.title,
    required this.message,
    required this.time,
    this.backgroundColor = Colors.white,
    this.titleColor = const Color(0xFF1F2937),
    this.hasUnreadDot = false,
    this.unreadDotColor = const Color(0xFF2A7DE1),
    this.actionButtons,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              iconContent,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (time.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            time,
                            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                          ),
                        ],
                        if (hasUnreadDot) ...[
                          const SizedBox(width: 8),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: unreadDotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14, height: 1.4),
                    ),
                    if (actionButtons != null) ...[
                      const SizedBox(height: 12),
                      Row(children: actionButtons!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
