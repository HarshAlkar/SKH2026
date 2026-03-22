import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hs053/core/routes/app_routes.dart';
import 'package:hs053/core/widgets/common_appbar.dart';
import 'package:hs053/features/asha_worker/widgets/asha_drawer.dart';
import '../widgets/stat_card.dart';
import '../widgets/health_chart.dart';
import '../widgets/progress_indicator_widget.dart';
import 'package:hs053/shared/providers/auth_provider.dart';
import '../widgets/village_selector_sheet.dart';
import 'package:intl/intl.dart';

class VillageHealthReportScreen extends StatefulWidget {
  const VillageHealthReportScreen({super.key});

  @override
  State<VillageHealthReportScreen> createState() => _VillageHealthReportScreenState();
}

class _VillageHealthReportScreenState extends State<VillageHealthReportScreen> {
  final Color primaryColor = const Color(0xFF2F4DB6);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  String _selectedVillage = "Rampur";
  DateTime _selectedDate = DateTime(2023, 10);
  bool _isUpdating = false;
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user != null) {
        _selectedVillage = user.village;
      }
      _isInit = false;
    }
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _simulateUpdate();
      });
    }
  }

  void _showVillageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => VillageSelectorSheet(
        selectedVillage: _selectedVillage,
        onVillageSelected: (village) {
          setState(() {
            _selectedVillage = village;
            _simulateUpdate();
          });
        },
      ),
    );
  }

  void _simulateUpdate() async {
    setState(() => _isUpdating = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: CommonAppBar(
        title: "Village Health Report",
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined, color: Colors.white, size: 20),
            onPressed: _selectDate,
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AshaDrawer(currentRoute: AppRoutes.villageHealthReport),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  // HEADER INFO SECTION
                  GestureDetector(
                    onTap: _showVillageSelector,
                    child: Container(
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                      ),
                      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24, top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: Colors.white70, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                "$_selectedVillage Village",
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              const Icon(Icons.arrow_drop_down, color: Colors.white70),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                DateFormat('MMMM yyyy').format(_selectedDate),
                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.calendar_month, color: Colors.white70, size: 16),
                            ],
                          ),
                        ],
                      ),
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
                                iconBackgroundColor: Colors.redAccent.withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        _buildSectionContainer(
                          title: "Disease Distribution",
                          actionText: "Details",
                          child: const HealthChart(),
                        ),
                        const SizedBox(height: 24),

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

                        _buildSectionContainer(
                          title: "High Risk Monitoring",
                          child: SizedBox(
                            height: 120,
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isUpdating)
              Container(
                color: Colors.black12,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                        ),
                        const SizedBox(width: 16),
                        const Text("Updating village health data..."),
                      ],
                    ),
                  ),
                ),
              ),
          ],
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
