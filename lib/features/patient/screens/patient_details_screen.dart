import 'package:flutter/material.dart';
import '../models/patient_model.dart';
import './edit_patient_screen.dart';
import '../widgets/status_badge.dart';
import '../widgets/patient_info_row.dart';
import '../widgets/vitals_card.dart';
import '../widgets/symptom_pill.dart';
import '../../asha_worker/widgets/asha_drawer.dart';
import '../../asha_worker/screens/update_health_screen.dart';
import '../../referral/screens/emergency_referral_screen.dart';

class PatientDetailsScreen extends StatelessWidget {
  final PatientModel patient;

  const PatientDetailsScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2A7DE1);
    const Color darkBlue = Color(0xFF005BBC);
    const Color backgroundColor = Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Patient Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: darkBlue,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditPatientScreen(patient: patient),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AshaDrawer(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // PATIENT PROFILE CARD
            Container(
              margin: const EdgeInsets.all(16),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor.withOpacity(0.1),
                        ),
                        child: const CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Age: ${patient.age} • Village: ${patient.village}",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "+91 98765 43210",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(status: patient.status),
                    ],
                  ),
                ],
              ),
            ),

            // BASIC INFORMATION SECTION
            _buildSection(
              title: "Basic Information",
              child: Column(
                children: [
                  const PatientInfoRow(
                    label: "Patient ID",
                    value: "GP-HAR-2024-0891",
                  ),
                  const PatientInfoRow(label: "Gender", value: "Male"),
                  const PatientInfoRow(
                    label: "Blood Group",
                    value: "O+ Positive",
                  ),
                  PatientInfoRow(label: "Village", value: patient.village),
                  const PatientInfoRow(
                    label: "Phone Number",
                    value: "+91 98765 43210",
                  ),
                  const PatientInfoRow(
                    label: "Registration Date",
                    value: "Jan 12, 2024",
                  ),
                ],
              ),
            ),

            // LATEST HEALTH VITALS
            _buildSection(
              title: "Latest Health Vitals",
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                children: const [
                  VitalsCard(
                    label: "Temperature",
                    value: "98.6",
                    unit: "°F",
                    icon: Icons.thermostat_outlined,
                    color: Colors.orange,
                  ),
                  VitalsCard(
                    label: "Blood Pressure",
                    value: "120/80",
                    unit: "mmHg",
                    icon: Icons.monitor_heart_outlined,
                    color: Colors.redAccent,
                  ),
                  VitalsCard(
                    label: "Blood Sugar",
                    value: "100",
                    unit: "mg/dL",
                    icon: Icons.water_drop_outlined,
                    color: Colors.blue,
                  ),
                  VitalsCard(
                    label: "Weight",
                    value: "65",
                    unit: "kg",
                    icon: Icons.fitness_center_outlined,
                    color: Colors.green,
                  ),
                ],
              ),
            ),

            // REPORTED SYMPTOMS
            _buildSection(
              title: "Reported Symptoms",
              child: const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SymptomPill(label: "Headache"),
                  SymptomPill(label: "Mild Fever"),
                  SymptomPill(label: "Body Ache"),
                ],
              ),
            ),

            // MEDICAL HISTORY
            _buildSection(
              title: "Medical History",
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HistoryItem(
                    title: "Hypertension",
                    date: "Diagnosed in 2022",
                  ),
                  _HistoryItem(title: "Dust Allergy", date: "Reported in 2023"),
                ],
              ),
            ),

            // VISIT HISTORY
            _buildSection(
              title: "Recent Visits",
              child: Column(
                children: [
                  _buildVisitHistoryItem(
                    "May 10, 2024",
                    "Monthly routine checkup. Vitals updated and stable.",
                  ),
                  _buildVisitHistoryItem(
                    "Apr 08, 2024",
                    "Follow-up for mild headache. Advised rest.",
                  ),
                ],
              ),
            ),

            // ACTION BUTTONS
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              child: Column(
                children: [
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
                      icon: const Icon(Icons.edit_note, size: 22),
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const EmergencyReferralScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.emergency_share_outlined,
                        size: 20,
                      ),
                      label: const Text("Emergency Referral"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildVisitHistoryItem(String date, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 14,
                color: Color(0xFF005BBC),
              ),
              const SizedBox(width: 8),
              Text(
                date,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              const Text(
                "NORMAL",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String title;
  final String date;

  const _HistoryItem({required this.title, required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: Colors.green),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                date,
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
