import 'package:flutter/material.dart';
import 'create_prescription_screen.dart';
import 'video_consultation_screen.dart';
import 'package:hs053/core/services/api_service.dart';
import 'package:hs053/shared/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:hs053/core/models/patient_model.dart';
import 'package:hs053/core/services/signaling_service.dart';

class SymptomData {
  final String label;
  final Color bgColor;
  final Color textColor;

  SymptomData({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });
}

class PatientData {
  final String name;
  final String age;
  final String gender;
  final String village;
  final String bloodType;
  final String chronicConditions;
  final String pastSurgeries;
  final String allergies;
  final List<SymptomData> symptoms;
  final String aiInsights;

  PatientData({
    required this.name,
    required this.age,
    required this.gender,
    required this.village,
    required this.bloodType,
    required this.chronicConditions,
    required this.pastSurgeries,
    required this.allergies,
    required this.symptoms,
    required this.aiInsights,
  });

  factory PatientData.fromPatient(Patient p) {
    return PatientData(
      name: p.name,
      age: p.age,
      gender: 'N/A',
      village: p.village,
      bloodType: 'N/A',
      chronicConditions: 'N/A',
      pastSurgeries: 'N/A',
      allergies: 'N/A',
      symptoms: [],
      aiInsights: 'N/A',
    );
  }

  static PatientData getDummySarah() {
    return PatientData(
      name: 'Sarah Jenkins',
      age: '28',
      gender: 'Female',
      village: 'Green Valley, North District',
      bloodType: 'O Positive',
      chronicConditions: 'No known chronic conditions reported.',
      pastSurgeries: 'Appendectomy (2018)',
      allergies: 'Penicillin, Peanuts',
      symptoms: [
        SymptomData(label: 'High Fever (102°F)', bgColor: const Color(0xFFFFE4E6), textColor: const Color(0xFFE11D48)),
        SymptomData(label: 'Persistent Cough', bgColor: const Color(0xFFFFEDD5), textColor: const Color(0xFFEA580C)),
        SymptomData(label: 'Shortness of breath', bgColor: const Color(0xFFF1F5F9), textColor: const Color(0xFF475569)),
      ],
      aiInsights: 'Symptoms reported 48 hours ago. Pattern suggests upper respiratory infection. Recommended immediate vitals check and chest auscultation.',
    );
  }

  static PatientData getDummyRamesh() {
    return PatientData(
      name: 'Ramesh Patil',
      age: '45',
      gender: 'Male',
      village: 'Kaman Village, Sector 2',
      bloodType: 'A Positive',
      chronicConditions: 'Type 2 Diabetes (Managed)',
      pastSurgeries: 'None',
      allergies: 'Dust, Pollen',
      symptoms: [
        SymptomData(label: 'Joint Pain', bgColor: const Color(0xFFE0F2FE), textColor: const Color(0xFF0369A1)),
        SymptomData(label: 'Mild Fever', bgColor: const Color(0xFFFEF3C7), textColor: const Color(0xFFB45309)),
      ],
      aiInsights: 'History of diabetes. Recent joint pains could indicate inflammatory response. Monitor blood sugar levels and markers for rheumatoid factors.',
    );
  }

  static PatientData getDummyAmitabh() {
    return PatientData(
      name: 'Amitabh Bachchan',
      age: '78',
      gender: 'Male',
      village: 'Mumbai South, Juhu',
      bloodType: 'B Positive',
      chronicConditions: 'Hypertension, Asthma',
      pastSurgeries: 'Abdominal Surgery (2005)',
      allergies: 'None reported',
      symptoms: [
        SymptomData(label: 'Dizziness', bgColor: const Color(0xFFF3E8FF), textColor: const Color(0xFF7E22CE)),
        SymptomData(label: 'Chest Tightness', bgColor: const Color(0xFFFEE2E2), textColor: const Color(0xFFDC2626)),
      ],
      aiInsights: 'Patient is high-risk due to age and respiratory history. Chest tightness requires immediate ECG and vital monitoring.',
    );
  }

  static PatientData getDummySunita() {
    return PatientData(
      name: 'Sunita Deshmukh',
      age: '32',
      gender: 'Female',
      village: 'Pelhar, East District',
      bloodType: 'AB Positive',
      chronicConditions: 'None reported',
      pastSurgeries: 'C-Section (2020)',
      allergies: 'Sulfa Drugs',
      symptoms: [
        SymptomData(label: 'Headache', bgColor: const Color(0xFFF1F5F9), textColor: const Color(0xFF475569)),
        SymptomData(label: 'Nausea', bgColor: const Color(0xFFECFDF5), textColor: const Color(0xFF059669)),
      ],
      aiInsights: 'Possible migraine or hormonal imbalance. Check blood pressure and stress levels.',
    );
  }
}

class PatientDetailsScreen extends StatefulWidget {
  final dynamic patient;
  final PatientData? data;

  const PatientDetailsScreen({super.key, this.patient, this.data});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  late PatientData patientData;
  bool _isInitiatingCall = false;

  @override
  void initState() {
    super.initState();
    if (widget.patient is Patient) {
      patientData = PatientData.fromPatient(widget.patient as Patient);
    } else if (widget.patient is PatientData) {
      patientData = widget.patient as PatientData;
    } else if (widget.data != null) {
      patientData = widget.data!;
    } else {
      patientData = PatientData.getDummySarah();
    }
  }

  Future<void> _startVideoCall() async {
    // If we have a real patient object, we can use its ID.
    // If not, we can't really call the backend.
    if (widget.patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot call a dummy patient. Please select a registered patient.')),
      );
      return;
    }

    setState(() => _isInitiatingCall = true);
    try {
      final api = ApiService();
      final response = await api.post('/consultations/start/', body: {
        'patient_id': widget.patient!.id,
        'doctor_user_id': Provider.of<AuthProvider>(context, listen: false).user?.id,
        'call_type': 'VIDEO',
      });

      if (!mounted) return;

      // Emit call-request so the patient can receive the incoming call
      final signaling = SignalingService();
      signaling.sendCallRequest(
        receiverId: widget.patient!.userId.toString(),
        consultationId: response['id'].toString(),
        callerName: Provider.of<AuthProvider>(context, listen: false).user?.name ?? 'Doctor',
        callType: 'VIDEO',
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoConsultationScreen(
            consultationId: response['id'].toString(),
            patientName: patientData.name,
            isOfferer: true,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start call: $e')),
      );
    } finally {
      setState(() => _isInitiatingCall = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2A7DE1);
    const textGray = Color(0xFF6B7280);
    const bgGray = Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: bgGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Patient Details',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF1F2937)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: primaryBlue.withOpacity(0.1),
                    child: Text(
                      patientData.name.isNotEmpty ? patientData.name[0] : '?',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patientData.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${patientData.age} Years · ${patientData.gender} · ${patientData.village}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: textGray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'ABHA Verified',
                            style: TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isInitiatingCall ? null : _startVideoCall,
                      icon: _isInitiatingCall 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.videocam_rounded, color: Colors.white, size: 20),
                      label: const Text(
                        'VIDEO CONSULT',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.message_outlined, color: primaryBlue),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildInfoCard(
                    title: 'Current Symptoms',
                    icon: Icons.personal_injury_outlined,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: patientData.symptoms.isEmpty 
                        ? [const Text('No recent symptoms reported')]
                        : patientData.symptoms.map((s) => _buildSymptomBadge(s)).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    title: 'AI Insights & Triage',
                    icon: Icons.auto_awesome_outlined,
                    child: Text(
                      patientData.aiInsights,
                      style: const TextStyle(color: Color(0xFF374151), height: 1.5, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    title: 'Medical Background',
                    icon: Icons.history_edu_outlined,
                    child: Column(
                      children: [
                        _buildDetailRow('Blood Group', patientData.bloodType),
                        _buildDetailRow('Chronic', patientData.chronicConditions),
                        _buildDetailRow('Allergies', patientData.allergies),
                        _buildDetailRow('Surgeries', patientData.pastSurgeries),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        width: double.infinity,
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreatePrescriptionScreen()),
            );
          },
          backgroundColor: const Color(0xFF1F2937),
          elevation: 4,
          icon: const Icon(Icons.note_add_outlined, color: Colors.white),
          label: const Text(
            'CREATE PRESCRIPTION',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF2A7DE1)),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSymptomBadge(SymptomData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: data.bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        data.label,
        style: TextStyle(
          color: data.textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Color(0xFF1F2937), fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
