import 'package:flutter/material.dart';
import '../models/patient_model.dart';
import 'edit_patient_screen.dart';
import '../../asha_worker/screens/update_health_screen.dart';

class PatientDetailsScreen extends StatelessWidget {
  final PatientModel? patient;
  const PatientDetailsScreen({super.key, this.patient});

  @override
  Widget build(BuildContext context) {
    final p = patient;
    return Scaffold(
      appBar: AppBar(
        title: Text(p?.name ?? 'Patient Details', style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2F4DB6),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: p == null
          ? const Center(child: Text('No patient selected'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _row('Age', '${p.age}'),
                _row('Village', p.village),
                _row('Gender', p.gender.isEmpty ? '—' : p.gender),
                _row('Blood group', p.bloodGroup.isEmpty ? '—' : p.bloodGroup),
                _row('Phone', p.phoneNumber.isEmpty ? '—' : p.phoneNumber),
                _row('Address', p.address.isEmpty ? '—' : p.address),
                _row('History', p.medicalHistory.isEmpty ? '—' : p.medicalHistory),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditPatientScreen(patient: p)),
                  ),
                  child: const Text('Edit patient'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UpdateHealthScreen(initialPatientId: p.patientId),
                    ),
                  ),
                  child: const Text('Update vitals'),
                ),
              ],
            ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
