import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/user_sidebar.dart';


class AddMedicineScreen extends StatelessWidget {
  const AddMedicineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const UserSidebar(),
      appBar: AppBar(
        title: const Text('Add Medicine'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Medicine Details',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildTextField('Medicine Name', 'e.g. Paracetamol'),
            const SizedBox(height: 16),
            _buildTextField('Dosage', 'e.g. 1 Tablet'),
            const SizedBox(height: 16),
            _buildTextField('Timing', 'e.g. 08:00 AM'),
            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Save Medicine',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
