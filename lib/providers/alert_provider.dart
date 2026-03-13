import 'package:flutter/material.dart';
import '../models/alert_model.dart';

class AlertProvider extends ChangeNotifier {
  final List<AlertModel> _alerts = [];

  List<AlertModel> get alerts => _alerts;

  void addAlert(AlertModel alert) {
    _alerts.insert(0, alert);
    notifyListeners();
  }
}
