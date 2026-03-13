import 'package:flutter/material.dart';
import '../models/consultation_model.dart';

class ConsultationProvider extends ChangeNotifier {
  final List<ConsultationModel> _consultations = [];
  final bool _isLoading = false;

  List<ConsultationModel> get consultations => _consultations;
  bool get isLoading => _isLoading;

  Future<void> scheduleConsultation(ConsultationModel consultation) async {
    _consultations.add(consultation);
    notifyListeners();
  }
}
