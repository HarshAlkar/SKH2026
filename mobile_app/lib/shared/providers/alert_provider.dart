import 'package:flutter/material.dart';
import 'package:hs053/shared/models/alert_model.dart';
import 'package:hs053/core/services/api_service.dart';

class AlertProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<AlertModel> _alerts = [];
  bool _isLoading = false;

  List<AlertModel> get alerts => _alerts;
  bool get isLoading => _isLoading;

  Future<void> fetchAlerts() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/alerts/notifications/');
      
      if (response is List) {
        _alerts = response.map((json) => AlertModel.fromJson(json)).toList();
        // Since AlertModel.fromJson handles formatting timestamp string, 
        // if we want to sort, we'd need the real date.
        // My shared AlertModel doesn't expose the real date yet, 
        // but it parses it internally.
      }
    } catch (e) {
      debugPrint('Error fetching alerts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addAlert(AlertModel alert) {
    _alerts.insert(0, alert);
    notifyListeners();
  }
}
