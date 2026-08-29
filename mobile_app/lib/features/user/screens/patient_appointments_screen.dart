import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../services/doctor_service.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  State<PatientAppointmentsScreen> createState() => _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
  final DoctorService _doctorService = DoctorService();
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() => _isLoading = true);
    try {
      final data = await _doctorService.getPatientAppointments();
      if (mounted) {
        setState(() {
          _appointments = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load appointments')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Appointments', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAppointments,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _appointments.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 100),
                      Center(child: Text("No appointments scheduled", style: TextStyle(color: Colors.grey, fontSize: 16))),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _appointments.length,
                    itemBuilder: (context, index) {
                      final appt = _appointments[index];
                      return _buildAppointmentCard(appt);
                    },
                  ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appt) {
    final doctorName = appt['doctor_name'] ?? 'Doctor';
    final date = appt['appointment_date'] ?? '';
    final timeStr = appt['appointment_time'] ?? '';
    final type = appt['consultation_type'] ?? 'VIDEO';
    final status = (appt['status'] ?? 'Scheduled').toString().toUpperCase();

    // Format date and time
    String formattedDate = date;
    try {
      final dt = DateTime.parse(date);
      formattedDate = DateFormat('MMM dd, yyyy').format(dt);
    } catch (_) {}

    String formattedTime = timeStr;
    try {
      if (timeStr.length >= 5) {
        final timeParts = timeStr.split(':');
        final time = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
        formattedTime = time.format(context);
      }
    } catch (_) {}

    IconData typeIcon = Icons.videocam;
    if (type == 'AUDIO') typeIcon = Icons.phone;
    if (type == 'OFFLINE') typeIcon = Icons.home_work;

    Color statusColor = Colors.orange;
    if (status == 'COMPLETED') statusColor = Colors.green;
    if (status == 'CANCELLED') statusColor = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
              CircleAvatar(
                backgroundColor: AppColors.lightBlue,
                radius: 24,
                child: Icon(typeIcon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$type Consultation',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(formattedDate, style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w500, fontSize: 13)),
              const Spacer(),
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(formattedTime, style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w500, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
