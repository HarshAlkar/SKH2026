import 'dart:convert';
import '../../../core/database/database_service.dart';
import '../../../core/sync/sync_queue_service.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/sync/sync_service.dart';

class PatientService {
  final DatabaseService _dbService = DatabaseService();
  final SyncQueueService _syncQueue = SyncQueueService();
  late final SyncService _syncService;

  // Assume connectivity is injected globally usually, defining inline for scoped architecture tests
  final ConnectivityService _connectivityService = ConnectivityService();

  PatientService() {
    _syncService = SyncService(_connectivityService);
  }

  /// Get Local Village Patients
  Future<List<PatientModel>> getVillagePatients() async {
    final List<Map<String, dynamic>> maps = await _dbService.getAllData(
      'patients',
    );

    // Sort logic placeholder if required based on timestamps/relevance etc.
    return List.generate(maps.length, (i) {
      return PatientModel.fromJson(maps[i]);
    });
  }

  /// Registers a patient mapped offline initially
  Future<PatientModel> registerPatient(
    Map<String, dynamic> rawPatientData,
  ) async {
    final patientId =
        'PT-\${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    // Assemble robust PatientModel config validating mock strings out
    final newPatient = PatientModel(
      id: patientId,
      name: rawPatientData['name'] ?? 'Unknown',
      age: int.tryParse(rawPatientData['age']?.toString() ?? '0') ?? 0,
      village: rawPatientData['village'] ?? 'Unknown',
      phone: rawPatientData['phone'] ?? '0000000000',
      bloodGroup: rawPatientData['bloodGroup'] ?? 'Not Known',
      status: 'Stable',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    // 1. SAVE VIRTUALLY OFFLINE LOCALLY (SQLite Database Layer)
    await _dbService.insertData('patients', newPatient.toJson());

    // 2. ENQUEUE SAFELY ON THE BACKLOG
    await _syncQueue.addOperationToQueue(
      'register_patient',
      jsonEncode(newPatient.toJson()),
    );

    // 3. ATTEMPT SYNC DYNAMICALLY FOR THE END-USER'S PEACE OF MIND
    if (_connectivityService.isOnline) {
      _syncService.forceSync();
    }

    return newPatient;
  }

  /// Generic update endpoint capturing health checks
  Future<void> updatePatientHealth(
    String patientId,
    Map<String, dynamic> fieldsToUpdate,
  ) async {
    // Retrieve Patient, Update Mapping fields natively on local copy...
    // In this abstract layer simulation, simply enqueue the generic update pipeline.

    fieldsToUpdate['id'] = patientId;
    fieldsToUpdate['updatedAt'] = DateTime.now().toIso8601String();

    await _syncQueue.addOperationToQueue(
      'update_patient_health',
      jsonEncode(fieldsToUpdate),
    );

    if (_connectivityService.isOnline) {
      _syncService.forceSync();
    }
  }
}
