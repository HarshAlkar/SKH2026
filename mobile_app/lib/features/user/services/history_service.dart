import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';

class HistoryService {
  final String _baseUrl = ApiConstants.baseUrl;

  Future<Map<String, dynamic>?> getFullHistoryByAbha(String abhaId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/profile-by-abha/?abha_id=$abhaId'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('HistoryService Error: $e');
      return null;
    }
  }
}
