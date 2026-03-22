class SymptomModel {
  final String id;
  final String name;
  final String severity; // Low, Medium, High
  final DateTime onsetDate;

  SymptomModel({
    required this.id,
    required this.name,
    required this.severity,
    required this.onsetDate,
  });

  factory SymptomModel.fromJson(Map<String, dynamic> json) {
    return SymptomModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      severity: json['severity'] ?? 'Low',
      onsetDate: DateTime.tryParse(json['onset_date'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'severity': severity,
    'onset_date': onsetDate.toIso8601String(),
  };
}
