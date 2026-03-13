import 'package:flutter/material.dart';

class AshaDashboard extends StatelessWidget {
  const AshaDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ASHA Worker Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildActionItem('Register New Patient', Icons.person_add, Colors.blue),
          _buildActionItem('Active Patients', Icons.list_alt, Colors.green),
          _buildActionItem('Send Health Alerts', Icons.notification_important, Colors.red),
          _buildActionItem('Village Health Report', Icons.bar_chart, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildActionItem(String title, IconData icon, Color color) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}
