import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../constants/api_constants.dart';
import '../utils/network_errors.dart';
import '../security/secure_session_store.dart';
import 'storage_service.dart';

class ApiService {
  http.Client _client = _createClient();
  final StorageService _storageService = StorageService();
  final _session = SecureSessionStore.instance;
  static const Duration _timeout = Duration(seconds: 20);
  static const Duration _connectTimeout = Duration(seconds: 8);

  static const _authPaths = [
    '/auth/login',
    '/auth/register',
    '/auth/send-otp',
    '/auth/verify-otp',
    '/auth/reset-password',
  ];

  static http.Client _createClient() {
    final inner = HttpClient()..connectionTimeout = _connectTimeout;
    return IOClient(inner);
  }

  void _resetClient() {
    try {
      _client.close();
    } catch (_) {}
    _client = _createClient();
  }

  bool _skipAuth(String endpoint) {
    return _authPaths.any(endpoint.contains);
  }

  Future<Map<String, String>> _getHeaders(
    String endpoint,
    Map<String, String>? extra,
  ) async {
    final token = _skipAuth(endpoint) ? null : await _session.readToken();
    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Token $token',
      ...?extra,
    };
  }

  Uri _uri(String endpoint) => Uri.parse('${ApiConstants.baseUrl}$endpoint');

  Future<T> _send<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on TimeoutException {
      _resetClient();
      try {
        return await action();
      } on TimeoutException {
        throw Exception(friendlyNetworkError('timeout'));
      } on SocketException catch (e) {
        throw Exception(friendlyNetworkError(e));
      }
    } on SocketException catch (e) {
      _resetClient();
      throw Exception(friendlyNetworkError(e));
    } on HttpException catch (e) {
      _resetClient();
      throw Exception(friendlyNetworkError(e));
    } catch (e) {
      if (e is Exception && e.toString().contains('timeout')) {
        rethrow;
      }
      throw Exception(friendlyNetworkError(e));
    }
  }

  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    return _send(() async {
      debugPrint('API GET ${_uri(endpoint)}');
      final combinedHeaders = await _getHeaders(endpoint, headers);
      final response = await _client
          .get(_uri(endpoint), headers: combinedHeaders)
          .timeout(timeout ?? _timeout);
      return _processResponse(response);
    });
  }

  /// Authenticated binary download (e.g. private prescription files).
  Future<List<int>> getBytes(
    String endpoint, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    return _send(() async {
      final combinedHeaders = await _getHeaders(endpoint, headers);
      final response = await _client
          .get(_uri(endpoint), headers: combinedHeaders)
          .timeout(timeout ?? const Duration(seconds: 60));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      }
      String message = 'API Error: ${response.statusCode}';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['error'] != null) {
          message = body['error'].toString();
        } else if (body is Map && body['detail'] != null) {
          message = body['detail'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    });
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    Duration? timeout,
  }) async {
    return _send(() async {
      debugPrint('API POST ${_uri(endpoint)}');
      final combinedHeaders = await _getHeaders(endpoint, {
        'Content-Type': 'application/json',
        ...?headers,
      });
      final response = await _client
          .post(
            _uri(endpoint),
            headers: combinedHeaders,
            body: jsonEncode(body),
          )
          .timeout(timeout ?? _timeout);
      return _processResponse(response);
    });
  }

  Future<dynamic> put(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    Duration? timeout,
  }) async {
    return _send(() async {
      final combinedHeaders = await _getHeaders(endpoint, {
        'Content-Type': 'application/json',
        ...?headers,
      });
      final response = await _client
          .put(
            _uri(endpoint),
            headers: combinedHeaders,
            body: jsonEncode(body),
          )
          .timeout(timeout ?? _timeout);
      return _processResponse(response);
    });
  }

  Future<dynamic> patch(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    Duration? timeout,
  }) async {
    return _send(() async {
      final combinedHeaders = await _getHeaders(endpoint, {
        'Content-Type': 'application/json',
        ...?headers,
      });
      final response = await _client
          .patch(
            _uri(endpoint),
            headers: combinedHeaders,
            body: jsonEncode(body),
          )
          .timeout(timeout ?? _timeout);
      return _processResponse(response);
    });
  }

  Future<dynamic> delete(String endpoint, {Map<String, String>? headers}) async {
    return _send(() async {
      final combinedHeaders = await _getHeaders(endpoint, headers);
      final response = await _client
          .delete(_uri(endpoint), headers: combinedHeaders)
          .timeout(_timeout);
      return _processResponse(response);
    });
  }

  Future<dynamic> postMultipart(
    String endpoint, {
    File? file,
    List<int>? fileBytes,
    String? fileName,
    String field = 'image',
    Map<String, String>? fields,
    Duration? timeout,
  }) async {
    return _send(() async {
      final request = http.MultipartRequest('POST', _uri(endpoint));
      request.headers.addAll(await _getHeaders(endpoint, null));
      
      if (file != null) {
        request.files.add(await http.MultipartFile.fromPath(field, file.path));
      } else if (fileBytes != null && fileName != null) {
        request.files.add(http.MultipartFile.fromBytes(field, fileBytes, filename: fileName));
      } else {
        throw Exception('Must provide either file or (fileBytes and fileName)');
      }

      if (fields != null) {
        request.fields.addAll(fields);
      }
      final streamed = await _client.send(request).timeout(timeout ?? const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);
      return _processResponse(response);
    });
  }

  dynamic _processResponse(http.Response response) {
    final raw = response.body.trimLeft();
    if (raw.startsWith('<') ||
        (response.headers['content-type'] ?? '').contains('text/html')) {
      final lower = raw.toLowerCase();
      if (lower.contains('disallowedhost') || lower.contains('allowed_hosts')) {
        throw Exception(
          'Django blocked this device IP. Add it to ALLOWED_HOSTS (or keep DEBUG=True) and restart the server.',
        );
      }
      throw Exception(
        'Server returned an HTML error (${response.statusCode}) instead of JSON. Check Django logs.',
      );
    }

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
