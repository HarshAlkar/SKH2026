import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hs053/core/theme/app_colors.dart';
import 'package:hs053/core/routes/app_routes.dart';
import '../widgets/user_sidebar.dart';
import 'package:hs053/shared/providers/medicine_provider.dart';
import 'package:hs053/shared/models/medicine_model.dart';

class MedicineTrackerScreen extends StatefulWidget {
  const MedicineTrackerScreen({super.key});

  @override
  State<MedicineTrackerScreen> createState() => _MedicineTrackerScreenState();
}

class _MedicineTrackerScreenState extends State<MedicineTrackerScreen> {
  DateTime _selectedDate = DateTime.now();
  late List<DateTime> _weekDates;

  @override
  void initState() {
    super.initState();
    _weekDates = _generateWeekDisplayDates(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicineProvider>().loadMedicines();
    });
  }

  List<DateTime> _generateWeekDisplayDates(DateTime date) {
    // Show full week Monday to Sunday
    int dayOfWeek = date.weekday; 
    DateTime monday = date.subtract(Duration(days: dayOfWeek - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
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
            icon: const Icon(Icons.menu, color: Color(0xFF1E293B)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Medicine Tracker',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.timer_outlined, color: Color(0xFF1E293B)),
            onPressed: () {
              context.read<MedicineProvider>().testAlarm();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Test alarm scheduled for 10 seconds from now')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, color: Color(0xFF1E293B)),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                  _weekDates = _generateWeekDisplayDates(date);
                });
              }
            },
          ),
        ],
      ),
      body: Consumer<MedicineProvider>(
        builder: (context, provider, child) {
          final displayMedicines = provider.getMedicinesForDate(_selectedDate);
          
          return RefreshIndicator(
            onRefresh: provider.loadMedicines,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReminderCard(provider),
                    const SizedBox(height: 24),
                    _buildDateSelector(),
                    const SizedBox(height: 32),
                    _buildScheduleHeader(displayMedicines.length, _selectedDate),
                    const SizedBox(height: 16),
                    provider.isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : displayMedicines.isEmpty 
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Text(
                                "No medicines scheduled for this day",
                                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                              ),
                            ),
                          )
                        : _buildMedicineList(displayMedicines, provider),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: _buildAddMedicineButton(),
    );
  }

  Widget _buildReminderCard(MedicineProvider provider) {
    bool isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    MedicineModel? nextMed;
    if (isToday) {
      final upcoming = provider.todaysMedicines.where((m) => !m.isTaken).toList();
      if (upcoming.isNotEmpty) nextMed = upcoming.first;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nextMed != null 
                        ? 'Next: ${nextMed.reminderTime}'
                        : isToday ? 'No upcoming medicines' : 'Check schedule',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nextMed != null
                        ? "Time for ${nextMed.medicineName}"
                        : isToday ? "You're all set for now!" : "Schedule for ${DateFormat('MMM dd').format(_selectedDate)}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.alarm, color: AppColors.primary.withOpacity(0.2), size: 40),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                 Navigator.pushNamed(context, AppRoutes.medicineSchedule);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: const Text('View Full Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _weekDates.map((date) {
            bool isSelected = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(_selectedDate);
            bool isToday = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(DateTime.now());
            
            return GestureDetector(
              onTap: () => setState(() => _selectedDate = date),
              child: Container(
                width: 50,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isToday && !isSelected ? Border.all(color: AppColors.primary.withOpacity(0.3)) : null,
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('E').format(date).toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd').format(date),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildScheduleHeader(int count, DateTime date) {
    bool isToday = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(DateTime.now());
    String label = isToday ? "Today's Schedule" : "${DateFormat('MMM dd').format(date)} Schedule";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        Text(
          "$count Meds ${isToday ? 'Today' : ''}",
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildMedicineList(List<MedicineModel> medicines, MedicineProvider provider) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: medicines.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final med = medicines[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.medication, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.medicineName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(med.reminderTime, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                        const SizedBox(width: 12),
                        const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(med.dosage, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  med.isTaken ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: med.isTaken ? AppColors.primary : Colors.grey.shade300,
                ),
                onPressed: () => provider.toggleStatus(med.id!),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddMedicineButton() {
    return FloatingActionButton.extended(
      onPressed: () async {
        final result = await Navigator.pushNamed(context, AppRoutes.addMedicine);
        if (result == true) {
          context.read<MedicineProvider>().loadMedicines();
        }
      },
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text('Add Medicine', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      elevation: 4,
    );
  }
}
