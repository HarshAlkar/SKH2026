enum RiskLevel { normal, moderate, highRisk }

class HealthRecordModel {
  final int? patientId;
  final int? patientAge;
  final String patientName;
  final String village;
  final String temperature;
  final String bloodPressure;
  final String bloodSugar;
  final String weight;
  final String symptoms;
  final String lastUpdated;
  final RiskLevel riskLevel;
  final String? date;

  HealthRecordModel({
    this.patientId,
    this.patientAge,
    required this.patientName,
    required this.village,
    required this.temperature,
    required this.bloodPressure,
    required this.bloodSugar,
    required this.weight,
    required this.symptoms,
    required this.lastUpdated,
    required this.riskLevel,
    this.date,
  });

  factory HealthRecordModel.fromJson(Map<String, dynamic> json) {
    RiskLevel getRisk(dynamic val) {
      final s = val?.toString().toLowerCase();
      if (s == 'moderate' || s == 'warning') return RiskLevel.moderate;
      if (s == 'highrisk' || s == 'high' || s == 'critical') return RiskLevel.highRisk;
      return RiskLevel.normal;
    }

    String formatDate(String? iso) {
      if (iso == null || iso.isEmpty) return 'Unknown';
      try {
        final dt = DateTime.parse(iso);
        final diff = DateTime.now().difference(dt);
        if (diff.inDays > 1) return '${diff.inDays} days ago';
        if (diff.inDays == 1) return 'Yesterday';
        if (diff.inHours > 0) return '${diff.inHours} hrs ago';
        if (diff.inMinutes > 0) return '${diff.inMinutes} mins ago';
        return 'Just now';
      } catch (_) {
        return iso;
      }
    }

    return HealthRecordModel(
      patientId: int.tryParse(json['patientId']?.toString() ?? json['patient']?.toString() ?? '0'),
      patientAge: int.tryParse(json['patientAge']?.toString() ?? '0'),
      patientName: json['patientName'] ?? json['patient_name'] ?? 'Unknown',
      village: json['village'] ?? 'Unknown',
      temperature: json['temperature']?.toString() ?? '--',
      bloodPressure: json['bloodPressure'] ?? json['blood_pressure']?.toString() ?? '--',
      bloodSugar: json['bloodSugar'] ?? json['blood_sugar']?.toString() ?? '--',
      weight: json['weight']?.toString() ?? '--',
      symptoms: json['symptoms']?.toString() ?? 'No symptoms reported.',
      lastUpdated: formatDate(json['lastUpdated'] ?? json['created_at'] ?? json['timestamp']),
      riskLevel: getRisk(json['riskLevel'] ?? json['risk_level'] ?? json['severity']),
      date: json['created_at'] ?? json['date'],
    );
  }
}
