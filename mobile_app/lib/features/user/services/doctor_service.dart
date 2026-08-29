import '../../../core/services/api_service.dart';

class DoctorService {
  final ApiService _apiService = ApiService();

  Future<List<Map<String, dynamic>>> getDoctors() async {
    try {
      final response = await _apiService.get('/doctors/');
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      print('Error fetching doctors: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> startConsultation({
    int? doctorId,
    int? patientId,
    int? ashaId,
    required String callType,
    bool isEmergency = false,
  }) async {
    final body = <String, dynamic>{
      'call_type': callType,
      if (doctorId != null) 'doctor_id': doctorId,
      if (patientId != null) 'patient_id': patientId,
      if (ashaId != null) 'asha_id': ashaId,
      if (isEmergency) 'is_emergency': true,
    };
    final response = await _apiService.post('/consultations/start/', body: body);
    return Map<String, dynamic>.from(response);
  }

  Future<void> endConsultation(String consultationId) async {
    try {
      await _apiService.post('/consultations/$consultationId/end/');
    } catch (e) {
      print('Error ending consultation: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getConsultationHistory() async {
    try {
      final response = await _apiService.get('/consultations/history/');
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      print('Error fetching history: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> bookAppointment({
    required int doctorId,
    required String date,
    required String time,
    required String type,
    String notes = '',
  }) async {
    final body = <String, dynamic>{
      'doctor_id': doctorId,
      'appointment_date': date,
      'appointment_time': time,
      'consultation_type': type.toUpperCase(),
      'notes': notes,
    };
    final response = await _apiService.post('/consultations/appointments/', body: body);
    return Map<String, dynamic>.from(response);
  }

  Future<List<Map<String, dynamic>>> getPatientAppointments() async {
    try {
      final response = await _apiService.get('/consultations/appointments/');
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      print('Error fetching patient appointments: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> smartMatch(String symptoms) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final lowerSymptoms = symptoms.toLowerCase();
    String urgency = 'MODERATE';
    String specialization = 'General Physician';
    int doctorId = 0;
    String doctorName = 'Dr. Rajesh Sharma';

    if (lowerSymptoms.contains('chest pain') ||
        lowerSymptoms.contains('breathing') ||
        lowerSymptoms.contains('breath') ||
        lowerSymptoms.contains('unconscious') ||
        lowerSymptoms.contains('faint') ||
        lowerSymptoms.contains('heart')) {
      urgency = 'EMERGENCY';
      specialization = 'Cardiologist / Emergency Care';
    } else if (lowerSymptoms.contains('fever') && lowerSymptoms.contains('cough')) {
      urgency = 'MODERATE';
      specialization = 'General Physician';
    } else if (lowerSymptoms.contains('skin') || lowerSymptoms.contains('rash')) {
      urgency = 'LOW';
      specialization = 'Dermatologist';
    }

    final doctors = await getDoctors();
    if (doctors.isEmpty) {
      throw Exception('Unable to find a doctor for this specialization. Please try again later.');
    }

    final match = doctors.firstWhere(
      (d) => (d['specialization'] ?? '').toString().toLowerCase().contains(specialization.toLowerCase().split(' ')[0]),
      orElse: () => doctors.first,
    );
    doctorId = match['id'] ?? match['user_id'] ?? 0;
    if (doctorId == 0) {
      throw Exception('Invalid doctor configuration in the system.');
    }

    doctorName = 'Dr. ${match['full_name'] ?? 'Doctor'}';
    specialization = match['specialization'] ?? specialization;

    final now = DateTime.now();
    DateTime recommendedDate = now.add(const Duration(days: 1));
    String recommendedTime = '10:30:00';

    if (urgency == 'EMERGENCY') {
      recommendedDate = now;
      recommendedTime = '${(now.hour + 1).toString().padLeft(2, '0')}:00:00';
    }

    final List<String> altDates = [
      "${recommendedDate.year}-${recommendedDate.month.toString().padLeft(2, '0')}-${recommendedDate.day.toString().padLeft(2, '0')}",
      "${recommendedDate.add(const Duration(days: 1)).year}-${recommendedDate.add(const Duration(days: 1)).month.toString().padLeft(2, '0')}-${recommendedDate.add(const Duration(days: 1)).day.toString().padLeft(2, '0')}",
      "${recommendedDate.add(const Duration(days: 2)).year}-${recommendedDate.add(const Duration(days: 2)).month.toString().padLeft(2, '0')}-${recommendedDate.add(const Duration(days: 2)).day.toString().padLeft(2, '0')}",
    ];

    final List<String> altTimes = [
      '09:00:00',
      '10:30:00',
      '12:00:00',
      '14:30:00',
      '16:00:00'
    ];
    if (urgency == 'EMERGENCY' && !altTimes.contains(recommendedTime)) {
      altTimes.insert(0, recommendedTime);
    }

    return {
      "symptoms_analyzed": symptoms,
      "urgency": urgency,
      "recommended_specialization": specialization,
      "recommended_doctor": {
        "id": doctorId,
        "name": doctorName,
      },
      "recommended_date": altDates[0],
      "recommended_time": recommendedTime,
      "recommended_type": "VIDEO",
      "alternative_dates": altDates,
      "alternative_times": altTimes,
    };
  }
}
