import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import '../../../features/asha_worker/widgets/asha_drawer.dart';
import '../../../features/patient/screens/patient_details_screen.dart';
import '../../../features/patient/models/patient_model.dart';
import '../../../features/asha_worker/screens/update_health_screen.dart';

class ActivityDetailsScreen extends StatelessWidget {
  final ActivityModel activity;

  const ActivityDetailsScreen({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2F4DB6);
    const Color backgroundColor = Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Activity Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AshaDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ACTIVITY INFORMATION CARD
              Container(
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  children: [
                    _buildDetailRow(
                      Icons.person_outline,
                      "Patient Name",
                      activity.patientName,
                    ),
                    const Divider(height: 32),
                    _buildDetailRow(
                      Icons.info_outline,
                      "Activity Type",
                      activity.activityType,
                    ),
                    const Divider(height: 32),
                    _buildDetailRow(
                      Icons.access_time,
                      "Timestamp",
                      activity.timestamp,
                    ),
                    const Divider(height: 32),
                    _buildDetailRow(
                      Icons.assignment_ind_outlined,
                      "Reported by",
                      activity.reportedBy,
                    ),
                    const Divider(height: 32),
                    _buildDetailRow(
                      Icons.location_on_outlined,
                      "Village",
                      activity.village,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ACTIVITY DESCRIPTION
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  "ACTIVITY DESCRIPTION",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                child: Text(
                  activity.description,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[800],
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // ACTION BUTTONS
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientDetailsScreen(
                          patient: PatientModel(
                            name: activity.patientName,
                            age: 45, // Placeholder
                            village: activity.village,
                            status: 'Stable', // Placeholder
                          ),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.account_circle_outlined),
                  label: const Text("View Patient Profile"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: primaryColor),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UpdateHealthScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_note),
                  label: const Text("Update Health Records"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F5FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF2F4DB6)),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
