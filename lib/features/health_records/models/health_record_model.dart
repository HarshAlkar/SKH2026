enum RiskLevel { normal, moderate, highRisk }

class HealthRecordModel {
  final String patientName;
  final String village;
  final String temperature;
  final String bloodPressure;
  final String bloodSugar;
  final String weight;
  final String lastUpdated;
  final RiskLevel riskLevel;

  HealthRecordModel({
    required this.patientName,
    required this.village,
    required this.temperature,
    required this.bloodPressure,
    required this.bloodSugar,
    required this.weight,
    required this.lastUpdated,
    required this.riskLevel,
  });
}
