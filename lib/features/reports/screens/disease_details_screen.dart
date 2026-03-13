import 'package:flutter/material.dart';

class DiseaseDetailsScreen extends StatelessWidget {
  const DiseaseDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2F4DB6);
    const Color backgroundColor = Color(0xFFF5F7FA);

    final List<Map<String, dynamic>> diseaseData = [
      {
        'name': 'Malaria',
        'cases': 45,
        'trend': 'decreasing',
        'color': Colors.blue,
      },
      {
        'name': 'Dengue',
        'cases': 28,
        'trend': 'increasing',
        'color': Colors.red,
      },
      {
        'name': 'Typhoid',
        'cases': 32,
        'trend': 'stable',
        'color': Colors.orange,
      },
      {
        'name': 'Viral Fever',
        'cases': 156,
        'trend': 'increasing',
        'color': Colors.purple,
      },
      {
        'name': 'Skin Infections',
        'cases': 18,
        'trend': 'decreasing',
        'color': Colors.green,
      },
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Disease Breakdown",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "CURRENT PREVALENCE",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: diseaseData.length,
              itemBuilder: (context, index) {
                final disease = diseaseData[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 40,
                        decoration: BoxDecoration(
                          color: disease['color'],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              disease['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              "Regional impact analysis",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${disease['cases']} Cases",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                disease['trend'] == 'increasing'
                                    ? Icons.trending_up
                                    : disease['trend'] == 'decreasing'
                                    ? Icons.trending_down
                                    : Icons.trending_flat,
                                size: 14,
                                color: disease['trend'] == 'increasing'
                                    ? Colors.red
                                    : disease['trend'] == 'decreasing'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                disease['trend'].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: disease['trend'] == 'increasing'
                                      ? Colors.red
                                      : disease['trend'] == 'decreasing'
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryColor.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: primaryColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "Viral Fever cases have seen a 15% spike this week. Recommend increasing awareness about hydration and rest.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[900],
                        height: 1.4,
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
}
