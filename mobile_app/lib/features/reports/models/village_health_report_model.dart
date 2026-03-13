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
}
