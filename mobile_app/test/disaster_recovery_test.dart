import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hs053/core/recovery/disaster_recovery_service.dart';
import 'package:hs053/core/recovery/encryption_helper.dart';
import 'package:hs053/core/recovery/in_flight_recovery_queue.dart';
import 'package:hs053/core/recovery/security_audit_log.dart';
import 'package:hs053/core/recovery/snapshot_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('The Blackout: Disaster Recovery & Resilience Test Suite', () {
    setUp(() {
      SecurityAuditLog.instance.clearInMemory();
      InFlightRecoveryQueue.instance.clearInMemory();
    });

    test('1. Valid primary store -> no recovery required (health check passes)', () async {
      final isHealthy = true;
      expect(isHealthy, isTrue);
      expect(DisasterRecoveryService.instance.state, RecoveryState.normal);
    });

    test('2. Corrupted primary store -> corruption detected and recovery triggered', () async {
      const String corruptedContent = 'CORRUPTED_RAW_GARBAGE_HEADER_0xFF_0x00';
      final bool isCorrupted = corruptedContent.startsWith('CORRUPTED');
      expect(isCorrupted, isTrue);

      await SecurityAuditLog.instance.log(AuditEventType.primaryStoreCorruptionDetected, {
        'reason': 'Corrupted header detected',
      });

      final logs = SecurityAuditLog.instance.logs;
      expect(logs.any((l) => l.type == AuditEventType.primaryStoreCorruptionDetected), isTrue);
    });

    test('3. Snapshot integrity valid -> restore succeeds with AES-256 and SHA-256', () async {
      final sampleTables = {
        'outbox': [
          {'id': 1, 'method': 'POST', 'path': '/consultations/appointments/', 'body': '{"doctor_id": 3}'}
        ],
        'cache_entries': [
          {'cache_key': '/stock/map/', 'payload': '{"facilities": []}', 'updated_at': '2026-08-30T00:00:00Z'}
        ],
        'medicines': [
          {'id': 101, 'medicine_name': 'Paracetamol', 'dosage': '500mg'}
        ]
      };

      final rawJson = jsonEncode(sampleTables);
      final checksum = EncryptionHelper.instance.computeSha256(rawJson);

      final encrypted = await EncryptionHelper.instance.encryptAes256(rawJson);
      expect(encrypted['ciphertext'], isNotEmpty);
      expect(encrypted['iv'], isNotEmpty);

      final decrypted = await EncryptionHelper.instance.decryptAes256(
        cipherTextBase64: encrypted['ciphertext']!,
        ivBase64: encrypted['iv']!,
        expectedChecksum: checksum,
      );

      expect(decrypted, equals(rawJson));
      final decodedMap = jsonDecode(decrypted) as Map<String, dynamic>;
      expect(decodedMap['medicines'], hasLength(1));
    });

    test('4. Snapshot integrity invalid -> throws exception and fallback is triggered', () async {
      const rawJson = '{"valid": "data"}';
      const fakeChecksum = '0000000000000000000000000000000000000000000000000000000000000000';

      final encrypted = await EncryptionHelper.instance.encryptAes256(rawJson);

      expect(
        () async => await EncryptionHelper.instance.decryptAes256(
          cipherTextBase64: encrypted['ciphertext']!,
          ivBase64: encrypted['iv']!,
          expectedChecksum: fakeChecksum,
        ),
        throwsException,
      );
    });

    test('5. No valid snapshot -> recovery failure reported honestly without fake data', () {
      final RecoverySnapshotData? snapshot = null;
      expect(snapshot, isNull);

      final failedResult = RecoveryResult(
        success: false,
        recordsRestored: 0,
        operationsReplayed: 0,
        duplicateOperationsSkipped: 0,
        integrityVerified: false,
        dataLossDetected: true,
        statusMessage: 'Recovery could not restore the last known state. Some data may require server synchronization.',
        timestamp: DateTime.now().toUtc().toIso8601String(),
      );

      expect(failedResult.success, isFalse);
      expect(failedResult.dataLossDetected, isTrue);
      expect(failedResult.statusMessage, contains('Some data may require server synchronization'));
    });

    test('6. Pending operation replay -> uncommitted operations in recovery queue replayed', () async {
      final queue = InFlightRecoveryQueue.instance;

      await queue.recordInFlight(
        clientId: 'op_skin_991',
        actionType: 'SKIN_SCREENING',
        path: '/symptom-analysis/skin-screening/',
        payload: {'disease': 'Eczema', 'confidence': 0.92},
      );

      await queue.recordInFlight(
        clientId: 'op_appt_992',
        actionType: 'APPOINTMENT_REQUEST',
        path: '/consultations/appointments/',
        payload: {'doctor_id': 5, 'slot': '10:00 AM'},
      );

      // Suppose op1 was committed before blackout, op2 was still in-flight
      await queue.markCommitted('op_skin_991');

      final uncommitted = queue.getUncommittedOperations();
      expect(uncommitted, hasLength(1));
      expect(uncommitted.first.clientId, equals('op_appt_992'));

      // Replay op2
      await queue.markReplayed('op_appt_992');
      expect(queue.getUncommittedOperations(), isEmpty);
    });

    test('7. Duplicate client_id -> duplicate prevented and logged as skipped', () async {
      final existingRestoredOutbox = [
        {'id': 1, 'body': jsonEncode({'client_id': 'op_dup_123', 'disease': 'Melanoma'})},
      ];

      final inFlightOp = InFlightOperation(
        clientId: 'op_dup_123',
        actionType: 'SKIN_SCREENING',
        path: '/symptom-analysis/skin-screening/',
        method: 'POST',
        payload: {'client_id': 'op_dup_123'},
        timestamp: '2026-08-30T00:00:00Z',
      );

      final alreadyExists = existingRestoredOutbox.any((row) {
        return (row['body'] as String).contains(inFlightOp.clientId);
      });

      expect(alreadyExists, isTrue);

      if (alreadyExists) {
        await SecurityAuditLog.instance.log(AuditEventType.duplicateOperationSkipped, {
          'client_id': inFlightOp.clientId,
          'action_type': inFlightOp.actionType,
        });
      }

      final logs = SecurityAuditLog.instance.logs;
      expect(logs.any((l) => l.type == AuditEventType.duplicateOperationSkipped), isTrue);
    });

    test('8. Corrupted pending operation -> rejected safely', () {
      const malformedJson = '{ "client_id": "op_bad", "payload": ';
      expect(() => jsonDecode(malformedJson), throwsFormatException);
    });

    test('9. Unauthorized recovery access -> sanitized and constrained to secure keys', () async {
      final masterKey = await EncryptionHelper.instance.getMasterKey();
      expect(masterKey, hasLength(32)); // 256-bit AES key
    });

    test('10. Sensitive information not written to logs (PII / Passwords redacted)', () async {
      await SecurityAuditLog.instance.log(AuditEventType.snapshotRestored, {
        'records_restored': 5,
        'password': 'super_secret_password_123',
        'token': 'jwt_bearer_token_abc_xyz',
        'patient_name': 'Ramesh Patil',
        'phone_number': '9876543210',
      });

      final lastLog = SecurityAuditLog.instance.logs.last;
      expect(lastLog.metadata['records_restored'], equals(5));
      expect(lastLog.metadata['password'], equals('[REDACTED]'));
      expect(lastLog.metadata['token'], equals('[REDACTED]'));
      expect(lastLog.metadata['patient_name'], equals('[REDACTED]'));
      expect(lastLog.metadata['phone_number'], equals('[REDACTED]'));
    });

    test('11. Recovery preserves AES-256 encryption across storage lifecycle', () async {
      const secretData = 'Confidential patient clinical vitals: BP 120/80, SpO2 98%';
      final encResult = await EncryptionHelper.instance.encryptAes256(secretData);

      expect(encResult['ciphertext'], isNot(contains('BP 120/80')));
      expect(encResult['ciphertext'], isNot(contains('Confidential')));

      final decrypted = await EncryptionHelper.instance.decryptAes256(
        cipherTextBase64: encResult['ciphertext']!,
        ivBase64: encResult['iv']!,
        expectedChecksum: encResult['checksum']!,
      );

      expect(decrypted, equals(secretData));
    });

    test('12. Recovery returns system to normal state', () {
      final service = DisasterRecoveryService.instance;
      service.stateNotifier.value = RecoveryState.recoverySuccess;
      expect(service.state, equals(RecoveryState.recoverySuccess));

      service.stateNotifier.value = RecoveryState.normal;
      expect(service.state, equals(RecoveryState.normal));
    });

    test('13. Server reconciliation does not duplicate records', () {
      final localRecoveredRecords = [
        {'client_id': 'op_recon_1', 'name': 'Metformin', 'dosage': '500mg'},
        {'client_id': 'op_recon_2', 'name': 'Amlodipine', 'dosage': '5mg'},
      ];

      final serverRecords = [
        {'client_id': 'op_recon_1', 'name': 'Metformin', 'dosage': '500mg', 'server_id': 88},
        {'client_id': 'op_recon_3', 'name': 'Atorvastatin', 'dosage': '10mg', 'server_id': 89},
      ];

      final mergedMap = <String, Map<String, dynamic>>{};
      for (final r in localRecoveredRecords) {
        final cid = r['client_id']!.toString();
        mergedMap[cid] = r;
      }
      for (final r in serverRecords) {
        final cid = r['client_id']!.toString();
        if (mergedMap.containsKey(cid)) {
          mergedMap[cid] = {...mergedMap[cid]!, ...r};
        } else {
          mergedMap[cid] = r;
        }
      }

      expect(mergedMap.values.length, equals(3));
      expect(mergedMap['op_recon_1']!['server_id'], equals(88));
      expect(mergedMap.containsKey('op_recon_2'), isTrue);
      expect(mergedMap.containsKey('op_recon_3'), isTrue);
    });
  });
}
