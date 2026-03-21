import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'package:gal/gal.dart';
import '../../../core/services/api_service.dart';

class QRService {
  final ApiService _apiService = ApiService();

  /// Generates a QR data string based on ABHA ID and user info
  String generateQRData(String abhaId, String name, String phone) {
    final data = {
      'abha_id': abhaId,
      'name': name,
      'phone': phone,
      'type': 'VITALREACH_USER_QR',
      'version': '1.0'
    };
    return jsonEncode(data);
  }

  /// Downloads/Saves the QR image to the gallery
  Future<bool> saveQRCodeToGallery(Uint8List imageBytes, String fileName) async {
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) await Gal.requestAccess();

      // Write to temp file first as gal needs a path or bytes (recent versions support bytes)
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/$fileName.png';
      final file = File(imagePath);
      await file.writeAsBytes(imageBytes);

      await Gal.putImage(imagePath);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Shares the QR code as an image
  Future<void> shareQRCode(Uint8List imageBytes, String text) async {
    final directory = await getTemporaryDirectory();
    final imagePath = await File('${directory.path}/qr_code.png').create();
    await imagePath.writeAsBytes(imageBytes);
    
    await Share.shareXFiles([XFile(imagePath.path)], text: text);
  }
  
  /// Scans a QR code and fetches full patient history from the backend
  Future<Map<String, dynamic>?> fetchUserDetailsFromQR(String qrData) async {
    try {
      final data = jsonDecode(qrData);
      if (data['type'] != 'VITALREACH_USER_QR') return null;

      final abhaId = data['abha_id'];
      if (abhaId == null || abhaId.isEmpty) return data; // return local data if no abha id

      // Fetch full profile + prescriptions + reports from backend
      try {
        final response = await _apiService.get('/users/profile-by-abha/$abhaId/');
        return Map<String, dynamic>.from(response);
      } catch (_) {
        // Fallback: return QR-embedded data if network fails
        return Map<String, dynamic>.from(data);
      }
    } catch (e) {
      return null;
    }
  }
}

