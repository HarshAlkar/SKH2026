import 'package:flutter/material.dart';

class AudioConsultationScreen extends StatelessWidget {
  const AudioConsultationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2A7DE1);
    const textPrimary = Color(0xFF1F2937);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Audio Consultation',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, size: 80, color: primaryBlue),
            ),
            const SizedBox(height: 32),
            const Text(
              'Connecting to Audio Call...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please wait while we connect you with the patient.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('End Call', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
