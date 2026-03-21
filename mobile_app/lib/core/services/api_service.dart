import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'storage_service.dart';

class ApiService {
  final http.Client _client = http.Client();

  final StorageService _storageService = StorageService();
  String get baseUrl => ApiConstants.baseUrl;
  Future<String?> getToken() async => _storageService.getString('token');

<<<<<<< HEAD
  Future<Map<String, String>> _getHeaders({Map<String, String>? extra, bool includeToken = true}) async {
    final token = includeToken ? _storageService.getString('token') : null;
=======
  Future<Map<String, String>> _getHeaders(String endpoint, Map<String, String>? extra) async {
    final token = _storageService.getString('token');
    
    final isAuthEndpoint = endpoint.contains('login') || 
                           endpoint.contains('register') || 
                           endpoint.contains('send-otp') || 
                           endpoint.contains('verify-otp') || 
                           endpoint.contains('reset-password');

>>>>>>> fee035fdefda48dc95a9fb53f469dc6dcaed41aa
    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty && !isAuthEndpoint) 'Authorization': 'Token $token',
      ...?extra,
    };
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? headers, bool includeToken = true}) async {
    try {
<<<<<<< HEAD
      final combinedHeaders = await _getHeaders(extra: headers, includeToken: includeToken);
=======
      final combinedHeaders = await _getHeaders(endpoint, headers);
>>>>>>> fee035fdefda48dc95a9fb53f469dc6dcaed41aa
      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: combinedHeaders,
      );
      return _processResponse(response);

    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    bool includeToken = true,
  }) async {
    try {
<<<<<<< HEAD
      final combinedHeaders = await _getHeaders(extra: {
=======
      final combinedHeaders = await _getHeaders(endpoint, {
>>>>>>> fee035fdefda48dc95a9fb53f469dc6dcaed41aa
        'Content-Type': 'application/json',
        ...?headers,
      }, includeToken: includeToken);
      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: combinedHeaders,
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> put(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    bool includeToken = true,
  }) async {
    try {
<<<<<<< HEAD
      final combinedHeaders = await _getHeaders(extra: {
=======
      final combinedHeaders = await _getHeaders(endpoint, {
>>>>>>> fee035fdefda48dc95a9fb53f469dc6dcaed41aa
        'Content-Type': 'application/json',
        ...?headers,
      }, includeToken: includeToken);
      final response = await _client.put(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: combinedHeaders,
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      rethrow;
    }
  }

<<<<<<< HEAD
  Future<dynamic> delete(String endpoint, {Map<String, String>? headers, bool includeToken = true}) async {
    try {
      final combinedHeaders = await _getHeaders(extra: headers, includeToken: includeToken);
=======
  Future<dynamic> patch(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      final combinedHeaders = await _getHeaders(endpoint, {
        'Content-Type': 'application/json',
        ...?headers,
      });
      final response = await _client.patch(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: combinedHeaders,
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint, {Map<String, String>? headers}) async {
    try {
      final combinedHeaders = await _getHeaders(endpoint, headers);
>>>>>>> fee035fdefda48dc95a9fb53f469dc6dcaed41aa
      final response = await _client.delete(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: combinedHeaders,
      );
      return _processResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  dynamic _processResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (e) {
      // Not JSON
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body; 
      }
      throw Exception('Server returned invalid response (${response.statusCode})');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      String message = 'API Error: ${response.statusCode}';
      if (body is Map && body.containsKey('error')) {
        message = body['error'];
      } else if (body is Map && body.isNotEmpty) {
        // Handle DRF serializer errors
        final firstValue = body.values.first;
        if (firstValue is List) {
          message = firstValue.first.toString();
        } else {
          message = firstValue.toString();
        }
      }
      throw Exception(message);
    }
  }
}
