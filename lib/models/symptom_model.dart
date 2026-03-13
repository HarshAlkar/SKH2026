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
}
