import 'package:flutter/material.dart';

class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Villager Dashboard')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(context, 'Symptom Checker', Icons.health_and_safety, Colors.green),
          _buildCard(context, 'Medicine Tracker', Icons.medical_services, Colors.blue),
          _buildCard(context, 'Doctor Call', Icons.video_call, Colors.orange),
          _buildCard(context, 'Prescriptions', Icons.receipt_long, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
