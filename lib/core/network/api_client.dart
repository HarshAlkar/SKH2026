import '../services/api_service.dart';

class ApiClient {
  final ApiService _apiService = ApiService();

  // Unified client for all API calls
  Future<dynamic> request({
    required String path,
    required String method,
    Map<String, String>? headers,
    dynamic body,
  }) async {
    if (method == 'GET') {
      return await _apiService.get(path, headers: headers);
    } else if (method == 'POST') {
      return await _apiService.post(path, headers: headers, body: body);
    }
    // Add other methods if needed
  }
}
