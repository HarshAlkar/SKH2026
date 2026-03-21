import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import '../../../providers/auth_provider.dart';
import '../services/qr_service.dart';
import '../../../core/utils/helpers.dart';

class QRCodeScreen extends StatefulWidget {
  const QRCodeScreen({super.key});

  @override
  State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final QRService _qrService = QRService();

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final primaryColor = Theme.of(context).primaryColor;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not found")));
    }

    // Use real formatted ABHA ID from user profile (fetched from backend)
    final abhaId = (user.abhaId ?? '').isNotEmpty 
        ? user.abhaId! 
        : 'GENERATING...';
    final String qrData = abhaId; // QR should just contain the ABHA ID for easy lookup


    return Scaffold(
      appBar: AppBar(
        title: const Text("My Health ID Card"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            const Text(
              "Your unique digital health identity",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            
            // The Card Widget which will be captured
            Screenshot(
              controller: _screenshotController,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: primaryColor.withOpacity(0.2), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Card Header with Gradient
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        ),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.health_and_safety, color: Colors.blueAccent, size: 28),
                          ),
                          const SizedBox(width: 14),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "VITALREACH",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: 2,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "Digital Health Passport",
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10,
                                  color: Colors.blueAccent,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Icon(Icons.qr_code_scanner_rounded, color: Colors.white70, size: 20),
                              SizedBox(height: 2),
                              Text(
                                "SECURE",
                                style: TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Profile Section
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: primaryColor.withOpacity(0.2), width: 2),
                                ),
                                child: CircleAvatar(
                                  radius: 45,
                                  backgroundColor: primaryColor.withOpacity(0.05),
                                  child: Text(
                                    user.name?.isNotEmpty == true ? user.name![0].toUpperCase() : 'U',
                                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: primaryColor),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "HOLDER NAME",
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
                                    ),
                                    Text(
                                      user.name?.toUpperCase() ?? 'UNKNOWN USER',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "ABHA NUMBER",
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        abhaId,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace', // Use monospace for numbers
                                          color: Colors.blue,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                          const Divider(thickness: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 20),

                          // QR Code Section
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade100, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              size: 160.0,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.circle,
                                color: Color(0xFF0F172A),
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.circle,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.security_rounded, size: 14, color: Colors.green),
                              SizedBox(width: 6),
                              Text(
                                "VERIFIED DIGITAL IDENTITY",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.green,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Card Bottom Bar
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                      ),
                      child: const Text(
                        "GOVERNMENT OF VITALREACH HEALTH AUTHORITY",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Download & Share Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Helpers.showSnackBar(context, "Generating ID Card...");
                      final imageBytes = await _screenshotController.capture();
                      if (imageBytes != null) {
                        final success = await _qrService.saveQRCodeToGallery(imageBytes, "VReach_ID_${user.id}");
                        if (mounted) {
                          Helpers.showSnackBar(context, success ? "ID Card saved to gallery" : "Failed to save ID Card");
                        }
                      }
                    },
                    icon: const Icon(Icons.file_download_rounded, size: 20),
                    label: const Text("SAVE TO GALLERY"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: Colors.black45,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: IconButton(
                    onPressed: () async {
                       Helpers.showSnackBar(context, "Processing ID Card...");
                       final imageBytes = await _screenshotController.capture();
                       if (imageBytes != null) {
                         await _qrService.shareQRCode(imageBytes, "My VitalReach Digital Health ID");
                       }
                    },
                    icon: const Icon(Icons.share_rounded, color: Color(0xFF0F172A)),
                    tooltip: "Share Card",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
