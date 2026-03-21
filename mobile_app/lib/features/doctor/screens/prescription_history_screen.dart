import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/doctor_navigation_drawer.dart';
import '../../../features/user/services/doctor_service.dart';
import 'prescription_detail_screen.dart';
import '../../../core/services/pdf_service.dart';

class PrescriptionRecord {
  final int id;
  final String patientName;
  final int patientAge;
  final String patientVillage;
  final String patientGender;
  final String symptoms;
  final String diagnosis;
  final String notes;
  final String date;
  final String prescriptionSummary;
  final String doctorName;
  final String doctorPhone;
  final String doctorEmail;
  final List<dynamic> medications;

  PrescriptionRecord({
    required this.id,
    required this.patientName,
    required this.patientAge,
    required this.patientVillage,
    required this.patientGender,
    required this.symptoms,
    required this.diagnosis,
    required this.notes,
    required this.date,
    required this.prescriptionSummary,
    required this.doctorName,
    required this.doctorPhone,
    required this.doctorEmail,
    required this.medications,
  });

  factory PrescriptionRecord.fromJson(Map<String, dynamic> json) {
    DateTime? issuedAt;
    if (json['issued_at'] != null) {
      issuedAt = DateTime.parse(json['issued_at']);
    }
    
    return PrescriptionRecord(
      id: json['id'] ?? 0,
      patientName: json['patient_name'] ?? 'Unknown',
      patientAge: json['patient_age'] ?? 0,
      patientVillage: json['patient_village'] ?? 'Unknown',
      patientGender: json['patient_gender'] ?? 'Unknown',
      symptoms: json['symptoms'] ?? 'No symptoms recorded',
      diagnosis: json['diagnosis'] ?? 'No diagnosis recorded',
      notes: json['notes'] ?? '',
      date: issuedAt != null ? DateFormat('MMM dd, yyyy').format(issuedAt) : 'N/A',
      prescriptionSummary: json['prescription_summary'] ?? 'No summary available',
      doctorName: json['doctor_name'] ?? 'Unknown Doctor',
      doctorPhone: json['doctor_phone'] ?? 'N/A',
      doctorEmail: json['doctor_email'] ?? 'N/A',
      medications: json['medications'] ?? [],
    );
  }
}

class PrescriptionHistoryScreen extends StatefulWidget {
  const PrescriptionHistoryScreen({super.key});

  @override
  State<PrescriptionHistoryScreen> createState() => _PrescriptionHistoryScreenState();
}

class _PrescriptionHistoryScreenState extends State<PrescriptionHistoryScreen> {
  final DoctorService _doctorService = DoctorService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<PrescriptionRecord> _prescriptions = [];
  List<PrescriptionRecord> _filteredPrescriptions = [];

  @override
  void initState() {
    super.initState();
    _fetchPrescriptions();
  }

  void _filterPrescriptions(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPrescriptions = _prescriptions;
      } else {
        _filteredPrescriptions = _prescriptions.where((prescription) {
          final nameMatched = prescription.patientName.toLowerCase().contains(query.toLowerCase());
          final diagnosisMatched = prescription.diagnosis.toLowerCase().contains(query.toLowerCase());
          return nameMatched || diagnosisMatched;
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPrescriptions() async {
    setState(() => _isLoading = true);
    try {
      final data = await _doctorService.getPrescriptions();
      setState(() {
        _prescriptions = data.map((json) => PrescriptionRecord.fromJson(json)).toList();
        _filteredPrescriptions = _prescriptions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading prescriptions: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF1F2937);
    const primaryBlue = Color(0xFF2A7DE1);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const DoctorNavigationDrawer(activeRoute: 'Prescriptions'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Prescription History',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: textPrimary),
            onPressed: _fetchPrescriptions,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPrescriptions.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredPrescriptions.length,
                        itemBuilder: (context, index) {
                          return _buildPrescriptionCard(_filteredPrescriptions[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterPrescriptions,
        decoration: InputDecoration(
          hintText: 'Search patient or diagnosis...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No prescriptions found',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(PrescriptionRecord record) {
    const primaryBlue = Color(0xFF2A7DE1);
    const textPrimary = Color(0xFF1F2937);
    const textSecondary = Color(0xFF6B7280);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFFF1F5F9),
                    child: Icon(Icons.person, color: primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.patientName,
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        record.date,
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Icon(Icons.assignment_turned_in, color: Colors.green, size: 20),
            ],
          ),
          const Divider(height: 32),
          Text(
            'DIAGNOSIS',
            style: TextStyle(
              color: textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            record.diagnosis,
            style: const TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Text(
            'SYMPTOMS',
            style: TextStyle(
              color: textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            record.symptoms,
            style: const TextStyle(color: textPrimary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          // Prescription Summary Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(color: primaryBlue, width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PRESCRIPTION SUMMARY',
                  style: TextStyle(
                    color: primaryBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  record.prescriptionSummary,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AGE', style: TextStyle(color: textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text('${record.patientAge}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('VILLAGE', style: TextStyle(color: textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text(record.patientVillage, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PrescriptionDetailScreen(record: record),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('View Report', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 44,
                height: 44,
                child: OutlinedButton(
                  onPressed: () {
                    PdfService.generatePrescriptionPdf(record);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: const Icon(Icons.download_outlined, color: textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
