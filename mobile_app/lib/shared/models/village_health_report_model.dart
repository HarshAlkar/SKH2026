class VillageHealthReportModel {
  final int totalPatients;
  final int recoveredCases;
  final int criticalCases;
  final Map<String, double> vaccinationRates;
  final Map<String, double> diseaseTrend;

  VillageHealthReportModel({
    required this.totalPatients,
    required this.recoveredCases,
    required this.criticalCases,
    required this.vaccinationRates,
    required this.diseaseTrend,
  });

  factory VillageHealthReportModel.fromJson(Map<String, dynamic> json) {
    return VillageHealthReportModel(
      totalPatients: int.tryParse(json['total_patients']?.toString() ?? '0') ?? 0,
      recoveredCases: int.tryParse(json['recovered_cases']?.toString() ?? '0') ?? 0,
      criticalCases: int.tryParse(json['critical_cases']?.toString() ?? '0') ?? 0,
      vaccinationRates: (json['vaccination_rates'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, (v as num).toDouble())) ?? {},
      diseaseTrend: (json['disease_trend'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, (v as num).toDouble())) ?? {},
    );
  }
}
