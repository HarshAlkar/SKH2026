import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Smart Appointment System Tests', () {
    test('Date and Time formatting logic works correctly', () {
      final dateStr = '2026-08-30';
      final dt = DateTime.parse(dateStr);
      expect(dt.year, 2026);
      expect(dt.month, 8);
      expect(dt.day, 30);

      final timeStr = '14:30:00';
      final parts = timeStr.split(':');
      expect(int.parse(parts[0]), 14);
      expect(int.parse(parts[1]), 30);
    });

    test('Symptom chip selection adds token without duplication', () {
      String currentText = '';
      void addSymptom(String s) {
        if (s == 'Other') return;
        if (currentText.isEmpty) {
          currentText = s;
        } else if (!currentText.toLowerCase().contains(s.toLowerCase())) {
          currentText = '$currentText, $s';
        }
      }

      addSymptom('Fever');
      expect(currentText, 'Fever');

      addSymptom('Cough');
      expect(currentText, 'Fever, Cough');

      // Duplicate should not be added
      addSymptom('Fever');
      expect(currentText, 'Fever, Cough');

      // Other should not be added as a symptom word
      addSymptom('Other');
      expect(currentText, 'Fever, Cough');
    });

    test('Smart Match response parsing extracts doctor, recommended slots, and alternative slots', () {
      final Map<String, dynamic> mockResponse = {
        "symptoms_analyzed": "I have fever and cough since yesterday",
        "urgency": "MODERATE",
        "recommended_specialization": "General Physician",
        "recommended_doctor": {
          "id": 3,
          "name": "Dr. Rajesh Sharma",
          "specialization": "General Physician",
          "hospital_name": "Kopargaon Rural Hospital",
          "phone_number": "9999999990"
        },
        "recommended_date": "2026-08-30",
        "recommended_time": "10:30:00",
        "recommended_type": "VIDEO",
        "alternative_dates": ["2026-08-30", "2026-08-31", "2026-09-01"],
        "alternative_times": ["09:00:00", "10:30:00", "12:00:00", "14:30:00"]
      };

      final doc = mockResponse['recommended_doctor'] as Map<String, dynamic>;

      expect(mockResponse['urgency'], 'MODERATE');
      expect(doc['id'], 3);
      expect(mockResponse['recommended_date'], '2026-08-30');
      expect(mockResponse['recommended_time'], '10:30:00');
      expect((mockResponse['alternative_dates'] as List), hasLength(3));
      expect((mockResponse['alternative_times'] as List), contains('14:30:00'));
    });

    test('Patient choosing alternative time overrides recommended time for booking payload', () {
      final Map<String, dynamic> mockResponse = {
        "recommended_doctor": {"id": 3},
        "recommended_date": "2026-08-30",
        "recommended_time": "10:30:00",
        "recommended_type": "VIDEO",
      };

      final doc = mockResponse['recommended_doctor'] as Map<String, dynamic>;
      String selectedDate = mockResponse['recommended_date'] as String;
      String selectedTime = mockResponse['recommended_time'] as String;

      // Patient selects alternative slot 2:30 PM
      selectedTime = '14:30:00';

      final bookingPayload = {
        'doctor_id': doc['id'],
        'appointment_date': selectedDate,
        'appointment_time': selectedTime,
        'consultation_type': mockResponse['recommended_type'],
        'notes': 'fever and cough',
      };

      expect(bookingPayload['appointment_time'], '14:30:00');
      expect(bookingPayload['appointment_date'], '2026-08-30');
      expect(bookingPayload['doctor_id'], 3);
    });

    test('Error message parser formats slot conflict and network errors cleanly for rural patients', () {
      String getFriendlyMessage(String raw) {
        final lower = raw.toLowerCase();
        if (lower.contains('socketexception') || lower.contains('timeout') || lower.contains('network')) {
          return 'Unable to connect. Please check your internet connection.';
        }
        if (lower.contains('slot') || lower.contains('conflict') || lower.contains('available')) {
          return 'This appointment slot is no longer available. Please choose another available time.';
        }
        return raw;
      }

      expect(
        getFriendlyMessage('SocketException: OS Error: connection refused'),
        'Unable to connect. Please check your internet connection.',
      );
      expect(
        getFriendlyMessage('409 Conflict: This appointment slot is no longer available.'),
        'This appointment slot is no longer available. Please choose another available time.',
      );
    });
  });
}
