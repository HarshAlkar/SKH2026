import 'package:flutter/material.dart';
import '../models/medicine_model.dart';
import '../core/services/medicine_db_service.dart';
import '../core/services/alarm_service.dart';
import '../core/sync/offline_api.dart';
import 'package:intl/intl.dart';

class MedicineProvider extends ChangeNotifier {
  final OfflineApi _apiService = OfflineApi.instance;
  final MedicineDbService _dbService = MedicineDbService.instance;

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
      // 1. Load from Local DB first (Offline support)
      _medicines = await _dbService.getAllMedicines();
      _updateTodaysMedicines();
      
      // 2. Reschedule all alarms to ensure they are active
      rescheduleAllAlarms();
      
      notifyListeners();

      // 3. Fetch from Backend and Sync
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
      // Check if current date falls between start and end date
      return m.startDate.compareTo(dateStr) <= 0 && m.endDate.compareTo(dateStr) >= 0;
    }).toList();
  }

  Future<void> addMedicine(MedicineModel medicine) async {
    // 1. Save to Local DB
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
    
    // 2. Schedule Alarm
    _scheduleAlarm(newMed);
    
    notifyListeners();

    // 3. Queue to cloud (syncs when internet is available)
    try {
      await _apiService.post('/medicines/add/', body: newMed.toJson());
    } catch (e) {
      debugPrint('Medicine queued for later sync: $e');
    }
  }

  void rescheduleAllAlarms() {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    
    for (var med in _medicines) {
      // Only schedule if medicine schedule hasn't ended
      if (med.endDate.compareTo(todayStr) >= 0) {
        _scheduleAlarm(med);
      }
    }
    debugPrint('All active medicine alarms rescheduled');
  }

  void snoozeMedicine(int id, String name, String instructions, String dosage) {
    final snoozeTime = DateTime.now().add(const Duration(minutes: 10));
    AlarmService.scheduleMedicineAlarm(id, snoozeTime, name, instructions, dosage);
    debugPrint('Medicine $name snoozed for 10 minutes');
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
        // Fallback to HH:mm (24h)
        try {
          final parts = med.reminderTime.split(':');
          parsed = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
        } catch (e2) {
          // Fallback to current time if format is completely broken
          parsed = now;
        }
      }

      DateTime alarmTime = DateTime(now.year, now.month, now.day, parsed.hour, parsed.minute);

      // If time has passed today, schedule for tomorrow
      if (alarmTime.isBefore(now)) {
        alarmTime = alarmTime.add(const Duration(days: 1));
      }
      
      // Ensure alarmTime is within medicine end date
      final endDate = DateFormat('yyyy-MM-dd').parse(med.endDate);
      final alarmDate = DateTime(alarmTime.year, alarmTime.month, alarmTime.day);
      
      if (alarmDate.isBefore(endDate.add(const Duration(days: 1)))) {
        AlarmService.scheduleMedicineAlarm(
          med.id ?? med.hashCode,
          alarmTime,
          med.medicineName,
          med.instructions,
          med.dosage,
        );
      }
    } catch (e) {
      debugPrint('Error scheduling alarm for ${med.medicineName}: $e');
    }
  }

  Future<void> toggleStatus(int id) async {
    final index = _medicines.indexWhere((m) => m.id == id);
    if (index != -1) {
      final updatedMed = MedicineModel(
        id: _medicines[index].id,
        medicineName: _medicines[index].medicineName,
        dosage: _medicines[index].dosage,
        frequency: _medicines[index].frequency,
        startDate: _medicines[index].startDate,
        endDate: _medicines[index].endDate,
        reminderTime: _medicines[index].reminderTime,
        instructions: _medicines[index].instructions,
        isTaken: !_medicines[index].isTaken,
        createdAt: _medicines[index].createdAt,
      );

      _medicines[index] = updatedMed;
      _updateTodaysMedicines();
      notifyListeners();

      // Update Local
      await _dbService.update(updatedMed);

      // Update Remote
      try {
        await _apiService.put('/medicines/update/${updatedMed.id}/', body: {'is_taken': updatedMed.isTaken});
      } catch (e) {
        debugPrint('Remote update failed: $e');
      }
    }
  }

  Future<void> syncWithBackend() async {
    try {
      final raw = await _apiService.get('/medicines/user/');
      final List<dynamic> response = raw is List ? raw : <dynamic>[];
      final remoteMeds = response.map((json) => MedicineModel.fromMap(json)).toList();

      bool hasChanges = false;
      for (var remoteMed in remoteMeds) {
        // Check if exists locally
        final localIndex = _medicines.indexWhere((m) => m.medicineName == remoteMed.medicineName && m.reminderTime == remoteMed.reminderTime);
        
        if (localIndex == -1) {
          // Add to local
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
    await AlarmService.cancelAlarm(id);

    try {
      await _apiService.delete('/medicines/remove/$id/');
    } catch (e) {
      debugPrint('Remote delete failed: $e');
    }
  }
}
