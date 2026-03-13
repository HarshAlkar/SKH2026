import 'package:flutter/material.dart';
import '../widgets/stat_card.dart';
import '../widgets/health_chart.dart';
import '../widgets/progress_indicator_widget.dart';

class VillageHealthReportScreen extends StatelessWidget {
  const VillageHealthReportScreen({super.key});

  final Color primaryColor = const Color(0xFF2F4DB6);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      // APP BAR
      appBar: AppBar(
        title: const Text(
          "Village Health Report",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // HEADER INFO SECTION
              Container(
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 24,
                  top: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          "Rampur Village",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          "October 2023",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // STATS SUMMARY CARDS
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            icon: Icons.people_outline,
                            label: "TOTAL",
                            value: "1,240",
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            icon: Icons.favorite_border,
                            label: "RECOVERED",
                            value: "856",
                            iconColor: Colors.green,
                            iconBackgroundColor: Colors.green.withOpacity(0.1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            icon: Icons.show_chart,
                            label: "CRITICAL",
                            value: "12",
                            iconColor: Colors.redAccent,
                            iconBackgroundColor: Colors.redAccent.withOpacity(
                              0.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // DISEASE DISTRIBUTION SECTION
                    _buildSectionContainer(
                      title: "Disease Distribution",
                      actionText: "Details",
                      child: const HealthChart(),
                    ),
                    const SizedBox(height: 24),

                    // VACCINATION COVERAGE SECTION
                    _buildSectionContainer(
                      title: "Vaccination Coverage",
                      child: const Column(
                        children: [
                          ProgressIndicatorWidget(
                            label: "Polio Drops (0-5 yrs)",
                            percentageText: "92%",
                            percentageValue: 0.92,
                          ),
                          SizedBox(height: 16),
                          ProgressIndicatorWidget(
                            label: "COVID-19 Booster",
                            percentageText: "78%",
                            percentageValue: 0.78,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // HIGH RISK MONITORING
                    _buildSectionContainer(
                      title: "High Risk Monitoring",
                      child: SizedBox(
                        height:
                            120, // Reduced height for minimalistic placeholder
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildMiniBar("Mon", 40),
                            _buildMiniBar("Tue", 60),
                            _buildMiniBar("Wed", 30),
                            _buildMiniBar("Thu", 80),
                            _buildMiniBar("Fri", 50),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    String? actionText,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (actionText != null)
                Text(
                  actionText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2F4DB6),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildMiniBar(String day, double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 8,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF2F4DB6).withOpacity(0.8),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 8),
        Text(day, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ],
    );
  }
}
