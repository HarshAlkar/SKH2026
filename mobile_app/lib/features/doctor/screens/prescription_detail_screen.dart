import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'prescription_history_screen.dart';
import '../../../core/services/pdf_service.dart';

class PrescriptionDetailScreen extends StatelessWidget {
  final PrescriptionRecord record;

  const PrescriptionDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2A7DE1);
    const textPrimary = Color(0xFF1F2937);
    const textSecondary = Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Prescription Report',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: primaryBlue),
            onPressed: () async {
              _showDownloadIndicator(context);
              await PdfService.generatePrescriptionPdf(record);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Center(
              child: Column(
                children: [
                  const Text(
                    'PRESCRIPTION',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF7C163C), // Maroon-ish from template
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(height: 4, width: 100, color: const Color(0xFFFF8A65)), // Orange line
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Top Info Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoColumn('Prescription No.', '000${record.id}', textSecondary, textPrimary),
                _buildInfoColumn('Prescription Date', record.date, textSecondary, textPrimary),
              ],
            ),
            const SizedBox(height: 32),

            // Patient Information
            _buildSectionHeader('Patient Information'),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildInfoColumn('Name', record.patientName, textSecondary, textPrimary)),
                Expanded(child: _buildInfoColumn('Age', '${record.patientAge}', textSecondary, textPrimary)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildInfoColumn('Village / Address', record.patientVillage, textSecondary, textPrimary)),
                Expanded(child: _buildInfoColumn('Gender', record.patientGender, textSecondary, textPrimary)),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoColumn('Symptoms', record.symptoms, textSecondary, textPrimary),
            const SizedBox(height: 16),
            _buildInfoColumn('Diagnosis', record.diagnosis, textSecondary, textPrimary),
            const SizedBox(height: 32),

            // Medications Table
            _buildSectionHeader('List of Prescribed Medications'),
            const SizedBox(height: 16),
            _buildMedicationTable(record.medications),

            const SizedBox(height: 48),

            // Notes
            if (record.notes.isNotEmpty) ...[
              const Text(
                'NOTES',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                record.notes,
                style: const TextStyle(fontSize: 14, color: textPrimary, height: 1.5),
              ),
              const SizedBox(height: 48),
            ],

            // Physician Signature
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Physician Name', style: TextStyle(fontSize: 12, color: textSecondary)),
                    Text(record.doctorName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    const Text('Physician Signature', style: TextStyle(fontSize: 12, color: textSecondary)),
                    const SizedBox(height: 8),
                    Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/3/3a/Jon_Kirsch_Signature.png',
                      height: 40,
                      errorBuilder: (context, error, stackTrace) => const Text('__________(Sig)__________'),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Contact Info', style: TextStyle(fontSize: 12, color: textSecondary)),
                    Text(record.doctorPhone, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    Text(record.doctorEmail, style: const TextStyle(fontSize: 14, color: textPrimary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFFE0B2), // Light orange background for headers
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF7C163C),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, Color labelColor, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: labelColor, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, color: valueColor, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMedicationTable(List<dynamic> medications) {
    return Table(
      border: TableBorder.all(color: Colors.blue.shade100, width: 1),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(2),
      },
      children: [
        // Header
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFE8EAF6)),
          children: [
            _buildTableCell('Medication', isHeader: true),
            _buildTableCell('Purpose', isHeader: true),
            _buildTableCell('Dosage', isHeader: true),
            _buildTableCell('Route', isHeader: true),
            _buildTableCell('Frequency', isHeader: true),
          ],
        ),
        // Rows
        ...medications.map((med) => TableRow(
          children: [
            _buildTableCell(med['name'] ?? 'N/A'),
            _buildTableCell(med['purpose'] ?? 'General'),
            _buildTableCell(med['dosage'] ?? 'N/A'),
            _buildTableCell(med['route'] ?? 'Oral'),
            _buildTableCell(med['timing'] ?? med['duration'] ?? 'N/A'),
          ],
        )),
      ],
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? const Color(0xFF283593) : Colors.black87,
        ),
      ),
    );
  }

  void _showDownloadIndicator(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 16),
            Text('Generating PDF...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
