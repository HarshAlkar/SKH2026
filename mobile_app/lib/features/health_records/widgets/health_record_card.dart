import 'package:flutter/material.dart';
import '../models/health_record_model.dart';
import 'risk_badge.dart';
import '../../asha_worker/screens/update_health_screen.dart';
import '../screens/record_details_screen.dart';

class HealthRecordCard extends StatelessWidget {
  final HealthRecordModel record;

  const HealthRecordCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2F4DB6);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.patientName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Village: \${record.village}",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RiskBadge(riskLevel: record.riskLevel),
                  const SizedBox(height: 4),
                  Text(
                    "Updated: \${record.lastUpdated}",
                    style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 16),
          // Vital Signs Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildVitalItem("Temp", "\${record.temperature}°F"),
              _buildVitalItem("BP", record.bloodPressure),
              _buildVitalItem("Sugar", "\${record.bloodSugar} mg/dL"),
              _buildVitalItem("Weight", "\${record.weight} kg"),
            ],
          ),
          const SizedBox(height: 20),
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RecordDetailsScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    "View Record",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UpdateHealthScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Update Health",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
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

  Widget _buildVitalItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
