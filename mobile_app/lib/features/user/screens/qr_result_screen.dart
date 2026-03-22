import 'package:flutter/material.dart';
import 'package:hs053/core/theme/app_colors.dart';

class QRScanResultScreen extends StatelessWidget {
  final Map<String, dynamic> details;
  const QRScanResultScreen({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Patient Verified', style: TextStyle(color: Color(0xFF1E293B))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status Header
            _buildVerifiedHeader(),
            const SizedBox(height: 24),
            
            // Personal & Medical Info
            _buildInfoCard(
              title: 'Personal Info',
              icon: Icons.person_outline,
              child: Column(
                children: [
                  _buildDetailRow('Name', details['name']),
                  _buildDetailRow('Phone', details['phone_number']),
                  _buildDetailRow('ABHA ID', details['abha_id']),
                  _buildDetailRow('Age', details['age'].toString()),
                  _buildDetailRow('Gender', details['gender']),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            _buildInfoCard(
              title: 'Emergency Medical Info',
              icon: Icons.emergency,
              iconColor: Colors.red,
              child: Column(
                children: [
                  _buildDetailRow('Blood Group', details['blood_group'] ?? 'N/A'),
                  _buildDetailRow('Allergies', details['allergies'] ?? 'None Reported'),
                  _buildDetailRow('Emergency Notes', details['emergency_notes'] ?? 'None'),
                  _buildDetailRow('Medical History', details['medical_history'] ?? 'No history'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Family Contacts
            _buildInfoCard(
              title: 'Family Contacts',
              icon: Icons.family_restroom,
              child: details['family_members'] == null || (details['family_members'] as List).isEmpty
                ? const Text('No family contacts listed.')
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: (details['family_members'] as List).length,
                    itemBuilder: (context, index) {
                      final f = details['family_members'][index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(f['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${f['relationship']} • ${f['phone_number']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.call, color: Colors.green),
                          onPressed: () {}, // add phone launcher if needed
                        ),
                      );
                    },
                  ),
            ),
            const SizedBox(height: 20),
            
            _buildInfoCard(
              title: 'Recent Prescriptions',
              icon: Icons.history_edu,
              child: details['prescriptions'] == null || (details['prescriptions'] as List).isEmpty
                ? const Text('No recent prescriptions found.')
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: (details['prescriptions'] as List).length,
                    itemBuilder: (context, index) {
                      final p = details['prescriptions'][index];
                      return ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text(p['medications'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('Dr. ${p['doctor']} • ${p['date']}'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(p['notes'] ?? 'No extra notes provided.', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                          ),
                        ],
                      );
                    },
                  ),
            ),
            const SizedBox(height: 40),
            
            _buildActionButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified, color: Colors.green),
          SizedBox(width: 12),
          Text(
            'Secure Patient ID Verified',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required Widget child, Color? iconColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor ?? const Color(0xFF2F4DB6)),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 32),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2F4DB6),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text('Close Verification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
