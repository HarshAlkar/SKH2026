class SymptomAnalysisResultModel {
  final String disease;
  final String severity;
  final String recommendation;
  final bool alertSent;
  final List<String> symptoms;

  SymptomAnalysisResultModel({
    required this.disease,
    required this.severity,
    required this.recommendation,
    required this.alertSent,
    required this.symptoms,
  });

  factory SymptomAnalysisResultModel.fromJson(Map<String, dynamic> json) {
    return SymptomAnalysisResultModel(
      disease: json['disease'] ?? 'Unknown',
      severity: json['severity'] ?? 'Low',
      recommendation: json['recommendation'] ?? '',
      alertSent: json['alert_sent'] ?? false,
      symptoms: List<String>.from(json['symptoms'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'disease': disease,
        'severity': severity,
        'recommendation': recommendation,
        'alert_sent': alertSent,
        'symptoms': symptoms,
      };
}
