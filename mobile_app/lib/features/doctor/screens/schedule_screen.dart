import 'package:flutter/material.dart';
import '../../../core/services/call_launcher.dart';
import '../../../routes/app_routes.dart';
import '../services/doctor_appointment_service.dart';
import 'patient_details_screen.dart';

class ScheduleScreen extends StatefulWidget {
  final bool embedded;
  const ScheduleScreen({super.key, this.embedded = false});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final DoctorAppointmentService _appointmentService = DoctorAppointmentService();
  String _selectedFilter = 'today'; // 'today', 'upcoming', 'all'
  List<DoctorAppointment> _appointments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? dateParam;
      if (_selectedFilter == 'today') {
        dateParam = 'today';
      } else if (_selectedFilter == 'upcoming') {
        dateParam = 'upcoming';
      }

      final list = await _appointmentService.getAppointments(date: dateParam);
      // Sort appointments chronologically by date and time
      list.sort((a, b) {
        final dateComp = a.rawDate.compareTo(b.rawDate);
        if (dateComp != 0) return dateComp;
        return a.rawTime.compareTo(b.rawTime);
      });

      if (!mounted) return;
      setState(() {
        _appointments = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load schedule. Please check your connection and try again.';
        _isLoading = false;
      });
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${weekdays[now.weekday - 1]} · ${months[now.month - 1]} ${now.day.toString().padLeft(2, '0')}, ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF1F2937);
    const backgroundColor = Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: !widget.embedded,
        leading: widget.embedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: textPrimary),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, AppRoutes.doctorDashboard);
                  }
                },
              ),
        title: const Text(
          "Doctor's Schedule",
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: textPrimary),
            onPressed: _loadAppointments,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAppointments,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateAndFilterHeader(),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateAndFilterHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getFormattedDate(),
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildFilterTab(
                  label: 'Today',
                  value: 'today',
                  showCheckIcon: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterTab(
                  label: 'Upcoming',
                  value: 'upcoming',
                  showCheckIcon: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterTab(
                  label: 'All Schedules',
                  value: 'all',
                  showCheckIcon: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab({
    required String label,
    required String value,
    bool showCheckIcon = false,
  }) {
    final isSelected = _selectedFilter == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_selectedFilter != value) {
            setState(() {
              _selectedFilter = value;
            });
            _loadAppointments();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2A7DE1) : const Color(0xFFEEF2F7),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected && showCheckIcon) ...[
                const Icon(
                  Icons.check,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A7DE1)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF4B5563), fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadAppointments,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A7DE1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_appointments.isEmpty) {
      String emptyMessage;
      if (_selectedFilter == 'today') {
        emptyMessage = 'No appointments scheduled for today.';
      } else if (_selectedFilter == 'upcoming') {
        emptyMessage = 'No upcoming appointments.';
      } else {
        emptyMessage = 'No schedules available.';
      }

      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          const Center(
            child: Icon(Icons.calendar_today_outlined, size: 56, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              emptyMessage,
              style: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Appointments booked by registered patients will appear here.',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _appointments.length,
      itemBuilder: (context, index) {
        return _buildAppointmentCard(context, _appointments[index]);
      },
    );
  }

  Widget _buildAppointmentCard(BuildContext context, DoctorAppointment appointment) {
    const textPrimary = Color(0xFF1F2937);
    const textSecondary = Color(0xFF6B7280);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Color(0xFF2A7DE1)),
                    const SizedBox(width: 6),
                    Text(
                      appointment.formattedTime,
                      style: const TextStyle(
                        color: Color(0xFF2A7DE1),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_selectedFilter != 'today' && appointment.rawDate.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '· ${appointment.rawDate}',
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                _buildTypeBadge(appointment.type),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFE8F1FF),
                  child: Text(
                    appointment.patientName.isNotEmpty
                        ? appointment.patientName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('')
                        : 'P',
                    style: const TextStyle(
                      color: Color(0xFF2A7DE1),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.patientName,
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Age: ${appointment.age} · Village: ${appointment.village}',
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildHistorySection(appointment),
            const SizedBox(height: 14),
            _buildActionButtons(context, appointment),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(DoctorConsultationType type) {
    Color color;
    IconData icon;
    String label;

    switch (type) {
      case DoctorConsultationType.video:
        color = const Color(0xFF2563EB);
        icon = Icons.videocam;
        label = 'Video Call';
        break;
      case DoctorConsultationType.audio:
        color = const Color(0xFF10B981);
        icon = Icons.phone;
        label = 'Audio Call';
        break;
      case DoctorConsultationType.offline:
        color = const Color(0xFFF59E0B);
        icon = Icons.local_hospital;
        label = 'Offline Visit';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(DoctorAppointment appointment) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              const Text(
                'PREVIOUS HEALTH HISTORY',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            appointment.historySummary.isNotEmpty
                ? appointment.historySummary
                : 'No previous health history on file.',
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (appointment.lastPrescription != null && appointment.lastPrescription!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Last Prescription: ${appointment.lastPrescription}',
                style: const TextStyle(
                  color: Color(0xFF1D4ED8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, DoctorAppointment appointment) {
    switch (appointment.type) {
      case DoctorConsultationType.video:
        return SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: () {
              final targetUserId = appointment.patientUserId?.toString() ?? appointment.patientId.toString();
              CallLauncher.start(
                context: context,
                peerName: appointment.patientName,
                receiverUserId: targetUserId,
                isVideo: true,
                doctorId: appointment.doctorId,
                patientId: appointment.patientId,
              );
            },
            icon: const Icon(Icons.videocam, size: 18),
            label: const Text('Start Video Call', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A7DE1),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );
      case DoctorConsultationType.audio:
        return SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: () {
              final targetUserId = appointment.patientUserId?.toString() ?? appointment.patientId.toString();
              CallLauncher.start(
                context: context,
                peerName: appointment.patientName,
                receiverUserId: targetUserId,
                isVideo: false,
                doctorId: appointment.doctorId,
                patientId: appointment.patientId,
              );
            },
            icon: const Icon(Icons.phone, size: 18),
            label: const Text('Start Audio Call', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );
      case DoctorConsultationType.offline:
        return SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PatientDetailsScreen(patient: appointment.toPatientData()),
                ),
              );
            },
            icon: const Icon(Icons.description_outlined, size: 18),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD97706),
              side: const BorderSide(color: Color(0xFFF59E0B)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            label: const Text('View Appointment Details', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
    }
  }
}
