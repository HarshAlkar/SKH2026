import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/medicine_provider.dart';

class MedicineReminderCallScreen extends StatelessWidget {
  final int medicineId;
  final String medicineName;
  final String dosage;
  final String instructions;

  const MedicineReminderCallScreen({
    super.key,
    required this.medicineId,
    required this.medicineName,
    required this.dosage,
    this.instructions = '',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Medicine Icon Animation
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              child: Icon(Icons.medication, size: 70, color: AppColors.primary),
            ),
            const SizedBox(height: 32),
            const Text(
              'MEDICINE REMINDER',
              style: TextStyle(color: Colors.white70, letterSpacing: 2, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              medicineName,
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Dosage: $dosage',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _circleButton(
                    onTap: () {
                      context.read<MedicineProvider>().snoozeMedicine(
                        medicineId, 
                        medicineName, 
                        instructions,
                        dosage
                      );
                      Navigator.pop(context);
                    },
                    icon: Icons.snooze,
                    color: Colors.orange,
                    label: 'Snooze',
                  ),
                  _circleButton(
                    onTap: () {
                      // Mark as taken
                      context.read<MedicineProvider>().toggleStatus(medicineId);
                      Navigator.pop(context);
                    },
                    icon: Icons.check,
                    color: Colors.green,
                    label: 'Taken',
                  ),
                  _circleButton(
                    onTap: () => Navigator.pop(context),
                    icon: Icons.close,
                    color: Colors.red,
                    label: 'Dismiss',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({required VoidCallback onTap, required IconData icon, required Color color, required String label}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
