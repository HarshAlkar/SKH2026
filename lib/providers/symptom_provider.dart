import 'package:flutter/material.dart';
import '../models/symptom_model.dart';

class SymptomProvider extends ChangeNotifier {
  final List<SymptomModel> _symptoms = [];
  final bool _isLoading = false;

  List<SymptomModel> get symptoms => _symptoms;
  bool get isLoading => _isLoading;

  void addSymptom(SymptomModel symptom) {
    _symptoms.add(symptom);
    notifyListeners();
  }
}
