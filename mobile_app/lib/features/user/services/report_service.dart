import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../models/report_model.dart';

class ReportService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final Connectivity _connectivity = Connectivity();

  Future<List<ReportModel>> getUserReports() async {
    final List<ConnectivityResult> connectivityResult = await _connectivity.checkConnectivity();
    final bool isOffline = connectivityResult.contains(ConnectivityResult.none);

    if (isOffline) {
       // Return cached data if offline
       final String? cached = _storageService.getString('cached_reports');
       if (cached != null) {
         final List list = jsonDecode(cached);
         return list.map((e) => ReportModel.fromJson(e)).toList();
       }
       return [];
    }

    try {
      final response = await _apiService.get('/records/reports/');
      final List list = List.from(response);
      
      // Cache for offline use
      await _storageService.saveString('cached_reports', jsonEncode(list));
      
      return list.map((e) => ReportModel.fromJson(e)).toList();
    } catch (e) {
       // fallback if API fails
       final String? cached = _storageService.getString('cached_reports');
       if (cached != null) {
         final List list = jsonDecode(cached);
         return list.map((e) => ReportModel.fromJson(e)).toList();
       }
       rethrow;
    }
  }

  Future<ReportModel> uploadReport({
    required String title,
    required String reportType,
    required String description,
    required File file,
  }) async {
    final token = await _apiService.getToken();
    final uri = Uri.parse('${_apiService.baseUrl}/records/reports/');
    
    var request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Token $token';
    request.fields['title'] = title;
    request.fields['report_type'] = reportType;
    request.fields['description'] = description;
    
    request.files.add(await http.MultipartFile.fromPath(
      'file_path',
      file.path,
    ));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ReportModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to upload report: ${response.statusCode}');
    }
  }

  Future<void> deleteReport(int reportId) async {
    await _apiService.delete('/records/reports/$reportId/');
    // Remove from cache: simple cache invalidation
    await _storageService.delete('cached_reports');
  }
}
