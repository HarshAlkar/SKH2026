import 'package:flutter/material.dart';

import '../../../core/services/medicine_db_service.dart';
import '../../../core/sync/offline_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../alerts/models/alert_model.dart';
import '../widgets/user_sidebar.dart';

class PatientAlertsScreen extends StatefulWidget {
  const PatientAlertsScreen({super.key});

  @override
  State<PatientAlertsScreen> createState() => _PatientAlertsScreenState();
}

class _PatientAlertsScreenState extends State<PatientAlertsScreen> {
  final OfflineApi _api = OfflineApi.instance;
  bool _loading = true;
  String? _error;
  List<AlertModel> _alerts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  TimeOfDay? _parseReminderTime(String timeStr) {
    try {
      final cleaned = timeStr.trim().replaceAll('\u202F', ' ').replaceAll('\u00A0', ' ');
      final isPm = cleaned.toLowerCase().contains('pm');
      final isAm = cleaned.toLowerCase().contains('am');
      
      final match = RegExp(r'(\d{1,2})[:.](\d{1,2})').firstMatch(cleaned);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        int minute = int.parse(match.group(2)!);
        if (isPm && hour < 12) hour += 12;
        if (isAm && hour == 12) hour = 0;
        if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    List<AlertModel> serverAlerts = [];
    List<AlertModel> medicineAlerts = [];

    // 1. Fetch Remote/Cached Screening & Emergency Alerts
    try {
      final response = await _api.get('/alerts/notifications/');
      final rows = response is List ? response : <dynamic>[];
      serverAlerts = rows
          .whereType<Map>()
          .map((row) => AlertModel.fromNotification(Map<String, dynamic>.from(row)))
          .toList();
    } catch (_) {
      // Offline fallback: continue to load local medicine alerts
    }

    // 2. Fetch Local Medicine Schedule Reminders (Offline first)
    try {
      final medicines = await MedicineDbService.instance.getAllMedicines();
      final now = DateTime.now();

      for (var med in medicines) {
        final time = _parseReminderTime(med.reminderTime);
        if (time == null) continue;

        final freq = med.frequency.trim().toLowerCase();

        if (freq == 'once' || freq == 'one-time' || freq == 'single') {
          DateTime? startDate;
          try {
            startDate = DateTime.parse(med.startDate);
          } catch (_) {}
          if (startDate == null) continue;

          final occurrence = DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
            time.hour,
            time.minute,
          );

          // Add if the scheduled reminder time has arrived
          if (!occurrence.isAfter(now)) {
            medicineAlerts.add(AlertModel.fromMedicineReminder(
              medicineId: med.id,
              medicineName: med.medicineName,
              dosage: med.dosage,
              reminderTime: med.reminderTime,
              scheduledDate: med.startDate,
              occurrenceTime: occurrence,
            ));
          }
        } else {
          // Daily recurring medicine
          DateTime? startDate;
          DateTime? endDate;
          try {
            startDate = DateTime.parse(med.startDate);
            endDate = DateTime.parse(med.endDate);
          } catch (_) {}
          if (startDate == null) continue;
          endDate ??= startDate.add(const Duration(days: 30));

          // Look back up to 14 days or startDate
          final minLookback = now.subtract(const Duration(days: 14));
          DateTime currentDay = startDate.isBefore(minLookback) ? minLookback : startDate;
          currentDay = DateTime(currentDay.year, currentDay.month, currentDay.day);

          while (!currentDay.isAfter(endDate) && !currentDay.isAfter(now)) {
            final occurrence = DateTime(
              currentDay.year,
              currentDay.month,
              currentDay.day,
              time.hour,
              time.minute,
            );

            if (!occurrence.isAfter(now)) {
              final dateFormatted =
                  "${currentDay.year.toString().padLeft(4, '0')}-${currentDay.month.toString().padLeft(2, '0')}-${currentDay.day.toString().padLeft(2, '0')}";
              medicineAlerts.add(AlertModel.fromMedicineReminder(
                medicineId: med.id,
                medicineName: med.medicineName,
                dosage: med.dosage,
                reminderTime: med.reminderTime,
                scheduledDate: dateFormatted,
                occurrenceTime: occurrence,
              ));
            }

            currentDay = currentDay.add(const Duration(days: 1));
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading local medicine notifications: $e');
    }

    final combined = [...medicineAlerts, ...serverAlerts];
    combined.sort((a, b) {
      final dtA = a.rawDateTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dtB = b.rawDateTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dtB.compareTo(dtA); // Newest first
    });

    if (mounted) {
      setState(() {
        _alerts = combined;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Notifications',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: AppColors.primary)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _alerts.isEmpty
              ? Center(child: Text(_error!))
              : _alerts.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No notifications yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _alerts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final alert = _alerts[index];
                          if (alert.isMedicineReminder) {
                            return _buildMedicineCard(alert);
                          }
                          return _buildServerAlertCard(alert);
                        },
                      ),
                    ),
    );
  }

  Widget _buildMedicineCard(AlertModel alert) {
    return InkWell(
      onTap: () {
        DateTime? targetDate;
        if (alert.scheduledDate != null && alert.scheduledDate!.isNotEmpty) {
          try {
            targetDate = DateTime.parse(alert.scheduledDate!);
          } catch (_) {}
        }
        Navigator.pushNamed(context, AppRoutes.medicineTracker, arguments: targetDate);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.medication, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '💊 Medicine Reminder',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        alert.timestamp,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.medicineName ?? 'Medicine',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alert.description,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, size: 12, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          'Scheduled: ${alert.reminderTime ?? ''}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
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

  Widget _buildServerAlertCard(AlertModel alert) {
    Color severityColor = AppColors.primary;
    if (alert.severityLevel == AlertSeverity.urgent) {
      severityColor = Colors.redAccent;
    } else if (alert.severityLevel == AlertSeverity.moderate) {
      severityColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: severityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    alert.alertType,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: severityColor == Colors.redAccent ? Colors.redAccent : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Text(
                alert.timestamp,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(alert.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
