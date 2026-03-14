import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/alert_provider.dart';
import '../../../core/theme/app_colors.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AlertProvider>(context, listen: false).fetchAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Consumer<AlertProvider>(
        builder: (context, alertProvider, _) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Urgent Patient Alerts'),
                if (alertProvider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (alertProvider.alerts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: Text('No urgent alerts at the moment')),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: alertProvider.alerts.length,
                    itemBuilder: (context, index) {
                      final alert = alertProvider.alerts[index];
                      return _buildAlertCard(alert);
                    },
                  ),
                _buildSectionHeader('Upcoming Consultations'),
                _buildMockConsultationList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildAlertCard(dynamic alert) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      shadowColor: Colors.black12,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: alert.severity == 'Emergency' ? Colors.red.shade50 : Colors.orange.shade50,
          child: Icon(
            alert.severity == 'Emergency' ? Icons.error_outline : Icons.warning_amber_rounded,
            color: alert.severity == 'Emergency' ? Colors.red : Colors.orange,
          ),
        ),
        title: Text(
          alert.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(alert.message),
            const SizedBox(height: 4),
            Text(
              '${_timeAgo(alert.timestamp)}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () {},
        ),
      ),
    );
  }

  Widget _buildMockConsultationList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 2,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text('Patient: ${index == 0 ? "Ramesh Patil" : "Sita Devi"}'),
            subtitle: Text('Scheduled for ${index == 0 ? "10:30 AM" : "11:45 AM"}'),
            trailing: const Icon(Icons.video_call, color: AppColors.primary),
            onTap: () {},
          ),
        );
      },
    );
  }

  String _timeAgo(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inMinutes < 60) return "${duration.inMinutes} mins ago";
    if (duration.inHours < 24) return "${duration.inHours} hrs ago";
    return "${duration.inDays} days ago";
  }
}
