import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ApiService {
  final http.Client _client = http.Client();

  Future<dynamic> get(String endpoint, {Map<String, String>? headers}) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: headers,
      );
      return _processResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, String>? headers, dynamic body}) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode}');
    }
  }
}
