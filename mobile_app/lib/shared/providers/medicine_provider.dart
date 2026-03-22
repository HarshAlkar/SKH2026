import 'package:flutter/material.dart';
import 'package:hs053/shared/models/medicine_model.dart';
import 'package:hs053/core/services/medicine_db_service.dart';
import 'package:hs053/core/services/api_service.dart';
import 'package:hs053/core/services/notification_service.dart';
import 'package:intl/intl.dart';

class MedicineProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final MedicineDbService _dbService = MedicineDbService.instance;
  final NotificationService _notificationService = NotificationService();

  List<MedicineModel> _medicines = [];
  List<MedicineModel> _todaysMedicines = [];
  bool _isLoading = false;

  List<MedicineModel> get medicines => _medicines;
  List<MedicineModel> get todaysMedicines => _todaysMedicines;
  bool get isLoading => _isLoading;

  Future<void> loadMedicines() async {
    _isLoading = true;
    notifyListeners();

    try {
      _medicines = await _dbService.getAllMedicines();
      _updateTodaysMedicines();
      
      // Reschedule alarms using the new NotificationService
      rescheduleAllAlarms();
      
      notifyListeners();
      await syncWithBackend();
    } catch (e) {
      debugPrint('Error loading medicines: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateTodaysMedicines() {
    _todaysMedicines = getMedicinesForDate(DateTime.now());
  }

  List<MedicineModel> getMedicinesForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return _medicines.where((m) {
      return m.startDate.compareTo(dateStr) <= 0 && m.endDate.compareTo(dateStr) >= 0;
    }).toList();
  }

  Future<void> addMedicine(MedicineModel medicine) async {
    final id = await _dbService.insert(medicine);
    final newMed = MedicineModel(
      id: id,
      medicineName: medicine.medicineName,
      dosage: medicine.dosage,
      frequency: medicine.frequency,
      startDate: medicine.startDate,
      endDate: medicine.endDate,
      reminderTime: medicine.reminderTime,
      instructions: medicine.instructions,
      isTaken: medicine.isTaken,
      createdAt: medicine.createdAt,
    );

    _medicines.add(newMed);
    _updateTodaysMedicines();
    _scheduleAlarm(newMed);
    
    notifyListeners();

    try {
      await _apiService.post('/medicines/add/', body: newMed.toJson());
    } catch (e) {
      debugPrint('Sync failed: $e');
    }
  }

  void rescheduleAllAlarms() {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    
    // Cancel all first to avoid duplicates
    _notificationService.cancelAll();

    for (var med in _medicines) {
      if (med.endDate.compareTo(todayStr) >= 0) {
        _scheduleAlarm(med);
      }
    }
    debugPrint('All medicine notifications rescheduled using zonedSchedule');
  }

  void snoozeMedicine(int id, String name, String instructions, String dosage) {
    final snoozeTime = DateTime.now().add(const Duration(minutes: 10));
    _notificationService.scheduleMedicineReminder(
      id: id,
      name: name,
      instructions: instructions,
      dosage: dosage,
      scheduledTime: snoozeTime,
    );
    notifyListeners();
  }

  void _scheduleAlarm(MedicineModel med) {
    try {
      final now = DateTime.now();
      DateFormat format = DateFormat("hh:mm a");
      DateTime parsed;
      
      try {
        parsed = format.parse(med.reminderTime);
      } catch (e) {
        try {
          final parts = med.reminderTime.split(':');
          parsed = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
        } catch (e2) {
          parsed = now;
        }
      }

      DateTime alarmTime = DateTime(now.year, now.month, now.day, parsed.hour, parsed.minute);

      if (alarmTime.isBefore(now)) {
        alarmTime = alarmTime.add(const Duration(days: 1));
      }
      
      final endDate = DateFormat('yyyy-MM-dd').parse(med.endDate);
      if (alarmTime.isBefore(endDate.add(const Duration(days: 1)))) {
        _notificationService.scheduleMedicineReminder(
          id: med.id ?? med.hashCode,
          name: med.medicineName,
          instructions: med.instructions,
          dosage: med.dosage,
          scheduledTime: alarmTime,
        );
      }
    } catch (e) {
      debugPrint('Error scheduling for ${med.medicineName}: $e');
    }
  }

  // Helper for testing
  void testAlarm() {
    _notificationService.testScheduledNotification();
  }

  Future<void> toggleStatus(int id) async {
    final index = _medicines.indexWhere((m) => m.id == id);
    if (index != -1) {
      final medicine = _medicines[index];
      final updatedMed = MedicineModel(
        id: medicine.id,
        medicineName: medicine.medicineName,
        dosage: medicine.dosage,
        frequency: medicine.frequency,
        startDate: medicine.startDate,
        endDate: medicine.endDate,
        reminderTime: medicine.reminderTime,
        instructions: medicine.instructions,
        isTaken: !medicine.isTaken,
        createdAt: medicine.createdAt,
      );

      _medicines[index] = updatedMed;
      _updateTodaysMedicines();
      notifyListeners();

      await _dbService.update(updatedMed);
      try {
        await _apiService.put('/medicines/update/${updatedMed.id}/', body: {'is_taken': updatedMed.isTaken});
      } catch (e) {
        debugPrint('Remote update failed: $e');
      }
    }
  }

  Future<void> syncWithBackend() async {
    try {
      final List<dynamic> response = await _apiService.get('/medicines/user/');
      final remoteMeds = response.map((json) => MedicineModel.fromMap(json)).toList();

      bool hasChanges = false;
      for (var remoteMed in remoteMeds) {
        final localIndex = _medicines.indexWhere((m) => m.medicineName == remoteMed.medicineName && m.reminderTime == remoteMed.reminderTime);
        if (localIndex == -1) {
          final id = await _dbService.insert(remoteMed);
          final newMed = MedicineModel.fromMap({...remoteMed.toMap(), 'id': id});
          _medicines.add(newMed);
          _scheduleAlarm(newMed);
          hasChanges = true;
        }
      }
      
      if (hasChanges) {
        _updateTodaysMedicines();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

  Future<void> removeMedicine(int id) async {
    _medicines.removeWhere((m) => m.id == id);
    _updateTodaysMedicines();
    notifyListeners();

    await _dbService.delete(id);
    await _notificationService.cancelNotification(id);

    try {
      await _apiService.delete('/medicines/remove/$id/');
    } catch (e) {
      debugPrint('Remote delete failed: $e');
    }
  }
}
