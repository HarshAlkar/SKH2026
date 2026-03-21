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
  });

  factory HealthRecordModel.fromJson(Map<String, dynamic> json) {
    RiskLevel getRisk(String? val) {
      if (val == 'moderate') return RiskLevel.moderate;
      if (val == 'highRisk' || val == 'high') return RiskLevel.highRisk;
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
        return 'Unknown';
      }
    }

    return HealthRecordModel(
      patientId: json['patientId'],
      patientAge: json['patientAge'],
      patientName: json['patientName'] ?? 'Unknown',
      village: json['village'] ?? 'Unknown',
      temperature: json['temperature']?.toString() ?? '--',
      bloodPressure: json['bloodPressure']?.toString() ?? '--',
      bloodSugar: json['bloodSugar']?.toString() ?? '--',
      weight: json['weight']?.toString() ?? '--',
      symptoms: json['symptoms']?.toString() ?? 'No symptoms reported.',
      lastUpdated: formatDate(json['lastUpdated']),
      riskLevel: getRisk(json['riskLevel']?.toString()),
    );
  }
}
