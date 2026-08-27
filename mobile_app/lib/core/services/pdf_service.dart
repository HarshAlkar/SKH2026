import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';

import 'file_save_service.dart';

class PdfService {
  static Future<String> generatePrescriptionPdf(
    Map<String, dynamic> data, {
    BuildContext? context,
  }) async {
    final pdf = pw.Document();
    final meds = (data['medications'] ?? '').toString();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('PRESCRIPTION', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              pw.Text('Doctor: ${data['doctor_name'] ?? '—'}'),
              pw.Text('Patient: ${data['patient_name'] ?? '—'}'),
              pw.Text('Date: ${data['issued_at'] ?? ''}'),
              pw.SizedBox(height: 16),
              pw.Text('Medications', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(meds.isEmpty ? 'None listed' : meds),
              pw.SizedBox(height: 12),
              pw.Text('Instructions: ${data['dosage_instructions'] ?? '—'}'),
              pw.Text('Notes: ${data['notes'] ?? '—'}'),
              pw.SizedBox(height: 24),
              pw.Text(
                'This is a digital copy from VitalReach. Not a substitute for in-person care.',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          );
        },
      ),
    );
    final bytes = await pdf.save();
    final safeName = (data['patient_name'] ?? data['doctor_name'] ?? 'prescription')
        .toString()
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final filename = 'VitalReach_prescription_$safeName.pdf';
    final path = await FileSaveService.saveBytes(
      bytes: bytes,
      filename: filename,
      context: context != null && context.mounted ? context : null,
    );
    try {
      await Printing.sharePdf(bytes: bytes, filename: filename);
    } catch (_) {}
    return path;
  }

  static Future<String> generateCallRecordPdf(
    Map<String, dynamic> data, {
    BuildContext? context,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('CALL RECORD', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              pw.Text('With: ${data['peer_name'] ?? '—'}'),
              pw.Text('Type: ${data['call_type'] ?? '—'}'),
              pw.Text('Status: ${data['status'] ?? '—'}'),
              pw.Text('Date: ${data['date'] ?? '—'}'),
              pw.Text('Duration: ${data['duration'] ?? '—'}'),
              pw.SizedBox(height: 12),
              pw.Text('Notes: ${data['notes'] ?? '—'}'),
            ],
          );
        },
      ),
    );
    final bytes = await pdf.save();
    final filename = 'VitalReach_call_${data['id'] ?? DateTime.now().millisecondsSinceEpoch}.pdf';
    return FileSaveService.saveBytes(
      bytes: bytes,
      filename: filename,
      context: context != null && context.mounted ? context : null,
    );
  }
}
