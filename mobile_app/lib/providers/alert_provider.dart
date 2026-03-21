import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../core/services/api_service.dart';
import '../core/services/storage_service.dart';

class AlertProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  List<AlertModel> _alerts = [];
  bool _isLoading = false;

  List<AlertModel> get alerts => _alerts;
  bool get isLoading => _isLoading;

  Future<void> fetchAlerts() async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = _storageService.getString('token');
      final response = await _apiService.get(
        '/alerts/notifications/',
        headers: token != null ? {'Authorization': 'Token $token'} : null,
      );
      
      if (response is List) {
        _alerts = response.map((json) {
          String sev = 'Info';
          if (json['severity'] == 'Critical' || json['severity'] == 'High') {
            sev = 'Emergency';
          } else if (json['severity'] == 'Moderate') sev = 'Warning';

          return AlertModel(
            id: json['id'].toString(),
            title: '${json['disease']} Alert',
            message: 'Patient: ${json['patient_name'] ?? 'Unknown'}. Status: ${json['severity']}',
            severity: sev,
            timestamp: DateTime.parse(json['created_at']),
          );
        }).toList();
        _alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
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
