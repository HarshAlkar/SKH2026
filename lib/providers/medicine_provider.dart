import 'package:flutter/material.dart';
import '../models/medicine_model.dart';

class MedicineProvider extends ChangeNotifier {
  final List<MedicineModel> _medicines = [];

  List<MedicineModel> get medicines => _medicines;

  void toggleStatus(String id) {
    final index = _medicines.indexWhere((m) => m.id == id);
    if (index != -1) {
      // Logic to toggle isTaken
      notifyListeners();
    }
  }
}
