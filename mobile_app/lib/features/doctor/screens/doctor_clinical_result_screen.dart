import 'package:flutter/material.dart';
import 'package:hs053/core/theme/app_colors.dart';

class DoctorClinicalResultScreen extends StatelessWidget {
  final Map<String, dynamic> details;
  const DoctorClinicalResultScreen({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    final basicInfo = details['basic_info'] ?? {};
    final medicalInfo = details['medical_info'] ?? {};
    final familyMembers = details['family_members'] as List<dynamic>? ?? [];
    final prescriptions = details['prescriptions'] as List<dynamic>? ?? [];
    final reports = details['reports'] as List<dynamic>? ?? [];
    final aiHistory = details['ai_history'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Clinical History', style: TextStyle(color: Color(0xFF1E293B))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Patient Header
            _buildPatientHeader(basicInfo),
            const SizedBox(height: 24),
            
            // Medical & Emergency Info
            _buildSection(
              title: 'Medical & Emergency Info',
              icon: Icons.emergency,
              color: Colors.red,
              child: Column(
                children: [
                  _buildDetailRow('Blood Group', medicalInfo['blood_group'] ?? 'N/A'),
                  _buildDetailRow('Allergies', medicalInfo['allergies'] ?? 'None Reported'),
                  _buildDetailRow('Emergency Notes', medicalInfo['emergency_notes'] ?? 'None'),
                  _buildDetailRow('Medical History', medicalInfo['medical_history'] ?? 'No history'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // AI Symptom History
            if (aiHistory.isNotEmpty)
              _buildSection(
                title: 'AI Symptom Analysis',
                icon: Icons.psychology,
                color: Colors.purple,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: aiHistory.length > 3 ? 3 : aiHistory.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final ai = aiHistory[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(ai['disease'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Severity: ${ai['severity']} • ${ai['date']}'),
                      trailing: const Icon(Icons.chevron_right),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),

            // Prescriptions
            _buildSection(
              title: 'Recent Prescriptions',
              icon: Icons.medication,
              color: Colors.blue,
              child: prescriptions.isEmpty 
                ? const Text('No recent prescriptions')
                : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: prescriptions.length > 5 ? 5 : prescriptions.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final p = prescriptions[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(p['medications'], maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('Dr. ${p['doctor']} • ${p['date']}'),
                      trailing: const Icon(Icons.description_outlined),
                    );
                  },
                ),
            ),
            const SizedBox(height: 20),

            // Diagnostic Reports
            _buildSection(
              title: 'Diagnostic Reports',
              icon: Icons.file_present,
              color: Colors.orange,
              child: reports.isEmpty 
                ? const Text('No reports uploaded')
                : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reports.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final r = reports[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(r['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(r['date']),
                      trailing: const Icon(Icons.remove_red_eye_outlined),
                      onTap: () {
                        // Open Report Viewer
                      },
                    );
                  },
                ),
            ),
            const SizedBox(height: 20),

            // Family Contacts
            _buildSection(
              title: 'Family Contacts',
              icon: Icons.family_restroom,
              color: Colors.green,
              child: familyMembers.isEmpty 
                ? const Text('No emergency contacts')
                : Column(
                  children: familyMembers.map<Widget>((m) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(m['name']),
                    subtitle: Text(m['relationship']),
                    trailing: Text(m['phone_number']),
                  )).toList(),
                ),
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F4DB6),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Done Reviewing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientHeader(Map<String, dynamic> info) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2F4DB6), Color(0xFF1E293B)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info['name'] ?? 'N/A', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text('${info['gender'] ?? 'N/A'} • ${info['age'] ?? 'N/A'} yrs', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(20)),
                  child: Text(info['abha_id'] ?? 'ABHA NOT FOUND', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required Widget child, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
        ],
      ),
    );
  }
}
