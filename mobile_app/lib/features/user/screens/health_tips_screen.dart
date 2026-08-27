import 'package:flutter/material.dart';

import '../../../core/services/settings_store.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/user_sidebar.dart';

class HealthTipsScreen extends StatelessWidget {
  const HealthTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hi = SettingsStore.instance.isHindi;
    final tips = [
      (
        hi ? 'हाइड्रेटेड रहें' : 'Stay Hydrated',
        hi ? 'रोज़ कम से कम 8 गिलास पानी पिएँ।' : 'Drink at least 8 glasses of water daily.',
        Icons.water_drop_outlined,
        const Color(0xFFE8F1FF),
      ),
      (
        hi ? 'सुबह की सैर' : 'Morning Walk',
        hi ? '15 मिनट की सैर ऊर्जा बढ़ाती है।' : 'A 15-minute walk boosts your energy.',
        Icons.directions_run_outlined,
        const Color(0xFFEFFFFA),
      ),
      (
        hi ? 'अच्छी नींद' : 'Sleep Well',
        hi ? 'हर रात 7–8 घंटे की नींद लें।' : 'Get 7-8 hours of quality sleep every night.',
        Icons.bedtime_outlined,
        const Color(0xFFFFF7EF),
      ),
      (
        hi ? 'हाथ धोएँ' : 'Wash hands',
        hi ? 'खाना खाने से पहले साबुन से हाथ धोएँ।' : 'Wash hands with soap before meals.',
        Icons.soap_outlined,
        const Color(0xFFE8F1FF),
      ),
      (
        hi ? 'संतुलित भोजन' : 'Eat balanced meals',
        hi ? 'फल, सब्ज़ी और दाल रोज़ शामिल करें।' : 'Include fruit, vegetables, and lentils every day.',
        Icons.restaurant_outlined,
        const Color(0xFFEFFFFA),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const UserSidebar(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.primary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          hi ? 'स्वास्थ्य सुझाव' : 'Health Tips',
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: tips.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final tip = tips[index];
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: tip.$4,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(tip.$3, color: Colors.blueGrey, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tip.$1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(tip.$2, style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
