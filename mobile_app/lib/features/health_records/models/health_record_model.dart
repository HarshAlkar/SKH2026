enum RiskLevel { normal, moderate, highRisk }

class HealthRecordModel {
  final int? id;
  final int? patientId;
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
    this.id,
    this.patientId,
    required this.patientName,
    required this.village,
    required this.temperature,
    required this.bloodPressure,
    required this.bloodSugar,
    required this.weight,
    this.symptoms = '',
    required this.lastUpdated,
    required this.riskLevel,
  });

  String get villageLabel => village.trim().isEmpty ? '--' : village;

  String get formattedUpdated {
    final dt = DateTime.tryParse(lastUpdated);
    if (dt == null) {
      return lastUpdated.trim().isEmpty ? '--' : lastUpdated;
    }
    final local = dt.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$d/$m/${local.year} $h:$min';
  }

  String vitalWithUnit(String value, String unit) {
    final v = value.trim();
    if (v.isEmpty || v == '--') return '--';
    if (v.toLowerCase().contains(unit.toLowerCase())) return v;
    return '$v $unit';
  }
}
