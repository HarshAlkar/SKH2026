import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/doctor/screens/prescription_history_screen.dart';

class PdfService {
  static Future<void> generatePrescriptionPdf(PrescriptionRecord record) async {
    final pdf = pw.Document();

    final maroon = PdfColor.fromHex('#7C163C');
    final orange = PdfColor.fromHex('#FF8A65');
    final lightOrange = PdfColor.fromHex('#FFE0B2');
    final cellBg = PdfColor.fromHex('#F5F5F5');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'PRESCRIPTION',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: maroon,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Container(height: 3, width: 80, color: orange),
                  ],
                ),
              ),
              pw.SizedBox(height: 40),

              // Date and No.
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildPdfInfoColumn('Prescription No.', '000${record.id}'),
                  _buildPdfInfoColumn('Prescription Date', record.date),
                ],
              ),
              pw.SizedBox(height: 25),

              // Patient Info Section
              _buildPdfSectionHeader('Patient Information', lightOrange, maroon),
              pw.SizedBox(height: 15),
              pw.Row(
                children: [
                  pw.Expanded(child: _buildPdfInfoColumn('Name', record.patientName)),
                  pw.Expanded(child: _buildPdfInfoColumn('Age', '${record.patientAge}')),
                ],
              ),
              pw.SizedBox(height: 15),
              pw.Row(
                children: [
                  pw.Expanded(child: _buildPdfInfoColumn('Address', record.patientVillage)),
                  pw.Expanded(child: _buildPdfInfoColumn('Gender', record.patientGender)),
                ],
              ),
              pw.SizedBox(height: 15),
              _buildPdfInfoColumn('Symptoms', record.symptoms),
              pw.SizedBox(height: 15),
              _buildPdfInfoColumn('Diagnosis', record.diagnosis),
              pw.SizedBox(height: 30),

              // Medications Table
              _buildPdfSectionHeader('List of Prescribed Medications', lightOrange, maroon),
              pw.SizedBox(height: 15),
              _buildPdfMedicationTable(record.medications, cellBg),

              pw.SizedBox(height: 30),
              if (record.notes.isNotEmpty) ...[
                pw.Text('NOTES', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.Text(record.notes, style: const pw.TextStyle(fontSize: 12)),
              ],

              pw.Spacer(),

              // Physician Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Physician Name', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(record.doctorName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 30),
                      pw.Container(
                        width: 150, 
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(width: 1))
                        ),
                      ),
                      pw.Text('Physician Signature', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Phone: ${record.doctorPhone}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Email: ${record.doctorEmail}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(record.date, style: const pw.TextStyle(fontSize: 10)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static pw.Widget _buildPdfSectionHeader(String title, PdfColor bgColor, PdfColor textColor) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: pw.BoxDecoration(color: bgColor),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: textColor),
      ),
    );
  }

  static pw.Widget _buildPdfInfoColumn(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _buildPdfMedicationTable(List<dynamic> medications, PdfColor headBg) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headBg),
          children: [
            _buildPdfTableCell('Medication', isHeader: true),
            _buildPdfTableCell('Purpose', isHeader: true),
            _buildPdfTableCell('Dosage', isHeader: true),
            _buildPdfTableCell('Route', isHeader: true),
            _buildPdfTableCell('Frequency', isHeader: true),
          ],
        ),
        ...medications.map((med) => pw.TableRow(
          children: [
            _buildPdfTableCell(med['name'] ?? 'N/A'),
            _buildPdfTableCell(med['purpose'] ?? 'General'),
            _buildTableCellValue(med['dosage'] ?? 'N/A'),
            _buildTableCellValue(med['route'] ?? 'Oral'),
            _buildPdfTableCell(med['timing'] ?? med['duration'] ?? 'N/A'),
          ],
        )),
      ],
    );
  }

  static pw.Widget _buildPdfTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCellValue(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }
}
