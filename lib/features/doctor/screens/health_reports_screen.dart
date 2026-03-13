import 'package:flutter/material.dart';

class HealthReportsScreen extends StatelessWidget {
  const HealthReportsScreen({super.key});

  final Color primaryBlue = const Color(0xFF2A7DE1);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.analytics_outlined, color: primaryBlue, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          'Health Reports',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: textPrimary),
                onPressed: () {},
              ),
              Positioned(
                right: 12,
                top: 14,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444), // Alert Color Red
                    shape: BoxShape.circle,
                  ),
                ),
              )
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0, left: 4.0),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: Color(0xFF1F2937),
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(
              title: 'TOTAL PATIENTS',
              value: '1,482',
              indicator: '+12%',
              subtext: 'From last month',
              icon: Icons.people_alt,
              iconColor: primaryBlue,
              isPositive: true,
            ),
            const SizedBox(height: 12),
            _buildSummaryCard(
              title: 'CRITICAL ALERTS',
              value: '08',
              indicator: '-5%',
              subtext: '2 resolved today',
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFEF4444),
              isPositive: false,
              isAlert: true,
            ),
            const SizedBox(height: 12),
            _buildSummaryCard(
              title: 'AVG. CONSULTATION',
              value: '18m',
              indicator: '+2%',
              subtext: 'Efficiency stable',
              icon: Icons.timer_outlined,
              iconColor: primaryBlue,
              isPositive: true,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Icon(Icons.bar_chart, color: primaryBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Medical Analytics Overview',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPatientVisitsChart(),
            const SizedBox(height: 16),
            _buildDiseaseTrendsChart(),
            const SizedBox(height: 16),
            _buildEmergencyAlerts(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String indicator,
    required String subtext,
    required IconData icon,
    required Color iconColor,
    required bool isPositive,
    bool isAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isAlert ? const Color(0xFFEF4444).withOpacity(0.2) : Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    indicator,
                    style: TextStyle(
                      color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtext,
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Icon(icon, color: iconColor, size: 28),
        ],
      ),
    );
  }

  Widget _buildPatientVisitsChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patient Visits',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '450',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '/mo',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar('MON', 0.8, false),
                _buildBar('TUE', 0.8, false),
                _buildBar('WED', 0.8, false),
                _buildBar('THU', 0.8, false),
                _buildBar('FRI', 0.8, false),
                _buildBar('SAT', 0.8, false),
                _buildBar('SUN', 0.8, true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String day, double heightFactor, bool isHighlighted) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 38,
              height: 140 * heightFactor,
              decoration: BoxDecoration(
                color: isHighlighted ? primaryBlue : const Color(0xFFBBE0FC), // Lighter blue for non-highlighted
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          day,
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDiseaseTrendsChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Disease Trends (Village)',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Infection Rate',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7), // Light yellow
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'MODERATE',
                  style: TextStyle(
                    color: Color(0xFFD97706), // Amber text
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: ChartLinePainter(primaryBlue: primaryBlue),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('JAN', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold)),
              Text('MAR', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold)),
              Text('MAY', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold)),
              Text('JUL', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold)),
              Text('SEP', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold)),
              Text('NOV', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEmergencyAlerts() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Emergency Alerts',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'View All',
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildAlertItem(
            title: 'Respiratory Distress',
            location: 'Block B - Ward 4, Bed 12',
            time: '2 mins ago',
            status: 'CRITICAL',
            icon: Icons.emergency,
            color: const Color(0xFFEF4444),
            bgColor: const Color(0xFFFEE2E2),
          ),
          const Divider(height: 24, color: Color(0xFFF3F4F6)),
          _buildAlertItem(
            title: 'Irregular Heart Rate',
            location: 'Outpatient Clinic - Rm 204',
            time: '15 mins ago',
            status: 'ALERT',
            icon: Icons.monitor_heart_outlined,
            color: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFEF3C7),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem({
    required String title,
    required String location,
    required String time,
    required String status,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    location,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Custom Painter for Smooth Line Chart
class ChartLinePainter extends CustomPainter {
  final Color primaryBlue;

  ChartLinePainter({required this.primaryBlue});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = primaryBlue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    var path = Path();
    path.moveTo(0, size.height * 0.7);

    // Creating a wave-like infection trend curve
    path.quadraticBezierTo(size.width * 0.15, size.height * 0.6, size.width * 0.3, size.height * 0.2);
    path.quadraticBezierTo(size.width * 0.5, size.height * -0.1, size.width * 0.65, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.85, size.height * 0.9, size.width, size.height * 0.4);

    // Gradient fill under the curve
    var paintFill = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [primaryBlue.withOpacity(0.15), Colors.white.withOpacity(0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    var fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
