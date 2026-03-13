import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../../providers/alert_provider.dart';
import '../../../models/alert_model.dart';
import '../widgets/user_sidebar.dart';



class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final List<String> _allSymptoms = [
    'Fever',
    'Cough',
    'Headache',
    'Vomiting',
    'Chest Pain',
    'Fatigue',
  ];

  final List<String> _selectedSymptoms = [];
  bool _isAnalyzing = false;
  bool _showResult = false;

  void _toggleSymptom(String symptom) {
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        _selectedSymptoms.remove(symptom);
      } else {
        _selectedSymptoms.add(symptom);
      }
    });
  }

  void _analyzeSymptoms() {
    if (_selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one symptom')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _showResult = false;
    });

    // Simulate AI Analysis
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _showResult = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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

        title: Column(
          children: [
            const Text(
              'AI Symptom Checker',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Gramin Health Connect',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How do you feel?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Our AI helps identify potential health concerns',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 32),
              const Text(
                'COMMON SYMPTOMS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _allSymptoms.map((symptom) {
                  final isSelected = _selectedSymptoms.contains(symptom);
                  return FilterChip(
                    label: Text(symptom),
                    selected: isSelected,
                    onSelected: (_) => _toggleSymptom(symptom),
                    selectedColor: AppColors.primary,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : const Color(0xFF2A7DE1).withOpacity(0.5),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),

                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              _buildVoiceInputSection(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isAnalyzing ? null : _analyzeSymptoms,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isAnalyzing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.analytics_outlined),
                            SizedBox(width: 12),
                            Text(
                              'Analyze Symptoms',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              if (_showResult) ...[
                const SizedBox(height: 32),
                _buildResultCard(),
                const SizedBox(height: 24),
                _buildSeverityIndicators(),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.consultDoctor),
                        icon: const Icon(Icons.video_call_outlined),
                        label: const Text('Consult Doctor'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final alertProvider = Provider.of<AlertProvider>(context, listen: false);
                          alertProvider.addAlert(
                            AlertModel(
                              id: DateTime.now().toString(),
                              title: 'Symptom Alert: Viral Fever',
                              message: 'Patient Ramesh reported symptoms and AI suggested Viral Fever (Moderate).',
                              severity: 'Warning',
                              timestamp: DateTime.now(),
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Alert sent to ASHA worker'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },

                        icon: const Icon(Icons.notification_important_outlined),
                        label: const Text('Notify ASHA'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceInputSection() {
    return CustomPaint(
      painter: DashRectPainter(color: AppColors.primary.withOpacity(0.3)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F1FF).withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(24),

        child: Column(
          children: [
            const Text(
              'Or describe symptoms by voice',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: IconButton(
                iconSize: 40,
                icon: const Icon(Icons.mic, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Voice input triggered...')),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tap to Speak',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ANALYSIS RESULT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 1.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7EF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(radius: 4, backgroundColor: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'MODERATE',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Viral Fever',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Possible seasonal viral infection. Maintain hydration and rest.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatusChip('MILD', Colors.green),
        _buildStatusChip('MODERATE', Colors.orange),
        _buildStatusChip('URGENT', Colors.red),
      ],
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    bool isResult = label == 'MODERATE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: isResult ? Border.all(color: color.withOpacity(0.3), width: 1.5) : null,
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 3, backgroundColor: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class DashRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashRectPainter({
    this.color = Colors.black,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint dashedPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    double x = size.width;
    double y = size.height;

    Path topPath = getDashedPath(const Offset(0, 0), Offset(x, 0), gap);
    Path rightPath = getDashedPath(Offset(x, 0), Offset(x, y), gap);
    Path bottomPath = getDashedPath(Offset(x, y), Offset(0, y), gap);
    Path leftPath = getDashedPath(Offset(0, y), const Offset(0, 0), gap);

    canvas.drawPath(topPath, dashedPaint);
    canvas.drawPath(rightPath, dashedPaint);
    canvas.drawPath(bottomPath, dashedPaint);
    canvas.drawPath(leftPath, dashedPaint);
  }

  Path getDashedPath(Offset start, Offset end, double gap) {
    Path path = Path();
    double distance = (end - start).distance;
    double dashWidth = gap;
    double dashSpace = gap;
    double currentDistance = 0;

    while (currentDistance < distance) {
      path.moveTo(
        start.dx + (end.dx - start.dx) * currentDistance / distance,
        start.dy + (end.dy - start.dy) * currentDistance / distance,
      );
      currentDistance += dashWidth;
      if (currentDistance > distance) currentDistance = distance;
      path.lineTo(
        start.dx + (end.dx - start.dx) * currentDistance / distance,
        start.dy + (end.dy - start.dy) * currentDistance / distance,
      );
      currentDistance += dashSpace;
    }
    return path;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
