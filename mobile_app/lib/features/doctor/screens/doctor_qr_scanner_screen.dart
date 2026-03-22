import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:hs053/shared/providers/profile_provider.dart';
import 'doctor_clinical_result_screen.dart';

class DoctorQRScannerScreen extends StatefulWidget {
  const DoctorQRScannerScreen({super.key});

  @override
  State<DoctorQRScannerScreen> createState() => _DoctorQRScannerScreenState();
}

class _DoctorQRScannerScreenState extends State<DoctorQRScannerScreen> {
  bool _isScanning = true;

  void _onDetect(BarcodeCapture capture) async {
    if (!_isScanning) return;

    try {
      final List<Barcode> barcodes = capture.barcodes;
      if (barcodes.isEmpty) return;

      final String? rawValue = barcodes.first.rawValue;
      if (rawValue == null || rawValue.trim().isEmpty) {
        debugPrint('DEBUG: Scanned QR data is null or empty');
        return;
      }

      final String abhaId = rawValue.trim();
      debugPrint('DEBUG: Processing Scanned ABHA ID: $abhaId');

      // Validation check
      if (abhaId.length < 5) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid QR Code Format'), backgroundColor: Colors.orange),
        );
        return;
      }

      setState(() => _isScanning = false);

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fetching Patient Clinical History...'), duration: Duration(seconds: 1)),
        );
      }

      final profileProvider = context.read<ProfileProvider>();
      final result = await profileProvider.lookupClinicalByQR(abhaId);

      if (!mounted) return;

      if (result != null) {
        debugPrint('DEBUG: lookupClinicalByQR Success for $abhaId');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorClinicalResultScreen(details: result),
          ),
        );
      } else {
        debugPrint('DEBUG: lookupClinicalByQR Failed or Result Null');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profileProvider.error ?? 'Patient record not found for this ABHA ID'),
            backgroundColor: Colors.red,
          ),
        );
        // Resume scanning after failure
        setState(() => _isScanning = true);
      }
    } catch (e, stack) {
      debugPrint('CRITICAL: QR Scanner Exception: $e');
      debugPrint(stack.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanner Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isScanning = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Patient QR'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2F4DB6), width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'Center the ABHA QR code within the frame',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
