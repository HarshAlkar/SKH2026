class MedicineModel {
  final String id;
  final String name;
  final String dosage;
  final String timing; // Before food, After food
  final bool isTaken;

  MedicineModel({
    required this.id,
    required this.name,
    required this.dosage,
    required this.timing,
    this.isTaken = false,
  });
}
