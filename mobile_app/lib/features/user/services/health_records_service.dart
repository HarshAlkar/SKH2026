import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/storage_service.dart';
import '../../../core/config/app_config.dart';

class HealthRecordsService {
  final StorageService _storageService = StorageService();

  Map<String, String> _authHeaders() {
    final token = _storageService.getString('token');
    return {
      'Authorization': 'Token $token',
    };
  }

  Future<List<Map<String, dynamic>>> getMyReports() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/records/reports/my-reports/'),
        headers: _authHeaders(),
      );
      if (response.statusCode == 200) {
        final list = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        await _storageService.saveString('cached_reports', jsonEncode(list));
        return list;
      }
      throw Exception('Failed to fetch reports: ${response.statusCode}');
    } catch (e) {
      // Offline fallback
      final cached = _storageService.getString('cached_reports');
      if (cached != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(cached));
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadReport({
    required File file,
    required String title,
    required String reportType,
    String description = '',
  }) async {
    final token = _storageService.getString('token');
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.baseUrl}/api/records/reports/'),
    );
    request.headers['Authorization'] = 'Token $token';
    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['report_type'] = reportType;
    request.files.add(await http.MultipartFile.fromPath('file_path', file.path));

    final streamResponse = await request.send();
    final response = await http.Response.fromStream(streamResponse);

    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }
    throw Exception('Upload failed: ${response.body}');
  }

  Future<void> deleteReport(int reportId) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.baseUrl}/api/records/reports/$reportId/'),
      headers: _authHeaders(),
    );
    if (response.statusCode != 204) {
      throw Exception('Delete failed: ${response.body}');
    }
  }
}
