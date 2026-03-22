import 'package:flutter/material.dart';
import 'package:hs053/shared/models/patient_model.dart';

class PatientProvider extends ChangeNotifier {
  final List<PatientModel> _patients = [];
  bool _isLoading = false;

  List<PatientModel> get patients => _patients;
  bool get isLoading => _isLoading;

  Future<void> fetchPatients() async {
    _isLoading = true;
    notifyListeners();
    // Fetch logic here
    _isLoading = false;
    notifyListeners();
  }
}
