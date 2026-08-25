import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> generatePrescriptionPdf(Map<String, dynamic> data) async {
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
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }
}
