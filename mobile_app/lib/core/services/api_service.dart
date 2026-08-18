import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../utils/network_errors.dart';
import 'storage_service.dart';

class ApiService {
  final http.Client _client = http.Client();
  final StorageService _storageService = StorageService();
  static const Duration _timeout = Duration(seconds: 15);

  Future<Map<String, String>> _getHeaders(Map<String, String>? extra) async {
    final token = _storageService.getString('token');
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
      ...?extra,
    };
  }

  Uri _uri(String endpoint) => Uri.parse('${ApiConstants.baseUrl}$endpoint');

  Future<dynamic> get(String endpoint, {Map<String, String>? headers}) async {
    try {
      final combinedHeaders = await _getHeaders(headers);
      final response = await _client
          .get(_uri(endpoint), headers: combinedHeaders)
          .timeout(_timeout);
      return _processResponse(response);
    } on TimeoutException {
      throw Exception(friendlyNetworkError('timeout'));
    } on SocketException catch (e) {
      throw Exception(friendlyNetworkError(e));
    } catch (e) {
      throw Exception(friendlyNetworkError(e));
    }
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      final combinedHeaders = await _getHeaders({
        'Content-Type': 'application/json',
        ...?headers,
      });
      final response = await _client
          .post(
            _uri(endpoint),
            headers: combinedHeaders,
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _processResponse(response);
    } on TimeoutException {
      throw Exception(friendlyNetworkError('timeout'));
    } on SocketException catch (e) {
      throw Exception(friendlyNetworkError(e));
    } catch (e) {
      throw Exception(friendlyNetworkError(e));
    }
  }

  Future<dynamic> put(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      final combinedHeaders = await _getHeaders({
        'Content-Type': 'application/json',
        ...?headers,
      });
      final response = await _client
          .put(
            _uri(endpoint),
            headers: combinedHeaders,
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _processResponse(response);
    } on TimeoutException {
      throw Exception(friendlyNetworkError('timeout'));
    } on SocketException catch (e) {
      throw Exception(friendlyNetworkError(e));
    } catch (e) {
      throw Exception(friendlyNetworkError(e));
    }
  }

  Future<dynamic> delete(String endpoint, {Map<String, String>? headers}) async {
    try {
      final combinedHeaders = await _getHeaders(headers);
      final response = await _client
          .delete(_uri(endpoint), headers: combinedHeaders)
          .timeout(_timeout);
      return _processResponse(response);
    } on TimeoutException {
      throw Exception(friendlyNetworkError('timeout'));
    } on SocketException catch (e) {
      throw Exception(friendlyNetworkError(e));
    } catch (e) {
      throw Exception(friendlyNetworkError(e));
    }
  }

  dynamic _processResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (e) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
      }
      throw Exception('Server returned invalid response (${response.statusCode})');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    String message = 'API Error: ${response.statusCode}';
    if (body is Map && body.containsKey('error')) {
      message = body['error'].toString();
    } else if (body is Map && body.containsKey('detail')) {
      message = body['detail'].toString();
    } else if (body is Map && body.isNotEmpty) {
      final firstValue = body.values.first;
      if (firstValue is List && firstValue.isNotEmpty) {
        message = firstValue.first.toString();
      } else {
        message = firstValue.toString();
      }
    }
    throw Exception(message);
  }
}
