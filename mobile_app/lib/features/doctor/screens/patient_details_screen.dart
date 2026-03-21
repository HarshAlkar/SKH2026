import 'package:flutter/material.dart';
import 'video_consultation_screen.dart';
import 'create_prescription_screen.dart';
import '../../user/services/doctor_service.dart';


class PatientData {
  final int id;
  final String name;
  final String age;
  final String gender;
  final String village;
  final String bloodType;
  final String chronicConditions;
  final String pastSurgeries;
  final String allergies;
  final String abhaId;
  final List<SymptomData> symptoms;
  final String aiInsights;
  final Map<String, dynamic>? emergencyContact;
  final List<dynamic>? familyMembers;
  final List<dynamic>? reports;

  PatientData({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.village,
    required this.bloodType,
    required this.chronicConditions,
    required this.pastSurgeries,
    required this.allergies,
    required this.abhaId,
    required this.symptoms,
    required this.aiInsights,
    this.emergencyContact,
    this.familyMembers,
    this.reports,
  });

  factory PatientData.fromJson(Map<String, dynamic> json) {
    final profile = json['profile_details'] ?? {};
    return PatientData(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['username'] ?? 'Unknown',
      age: (profile['age'] ?? 0).toString(),
      gender: profile['gender'] ?? 'Unknown',
      village: json['village'] ?? 'Unknown',
      bloodType: profile['blood_group'] ?? 'Unknown',
      chronicConditions: json['medical_history'] ?? 'None reported',
      pastSurgeries: json['past_surgeries'] ?? 'None reported',
      allergies: json['allergies'] ?? 'None reported',
      abhaId: json['abha_id'] ?? profile['abha_id'] ?? '',
      symptoms: [], 
      aiInsights: json['ai_insights'] ?? 'No AI insights available for this patient yet.',
      emergencyContact: json['emergency_contact'],
      familyMembers: json['family_members'],
      reports: json['reports'],
    );
  }

  static PatientData getDummySarah() {
    return PatientData(
      id: 6,
      name: 'Sarah Jenkins',
      age: '28',
      gender: 'Female',
      village: 'Green Valley, North District',
      bloodType: 'O Positive',
      chronicConditions: 'No known chronic conditions reported.',
      pastSurgeries: 'Appendectomy (2018)',
      allergies: 'Penicillin, Peanuts',
      abhaId: 'ABHA-1234-5678',
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
      id: 1,
      name: 'Ramesh Patil',
      age: '45',
      gender: 'Male',
      village: 'Kaman Village, Sector 2',
      bloodType: 'A Positive',
      chronicConditions: 'Type 2 Diabetes (Managed)',
      pastSurgeries: 'None',
      allergies: 'Dust, Pollen',
      abhaId: 'ABHA-1111-2222',
      symptoms: [
        SymptomData(label: 'Joint Pain', bgColor: const Color(0xFFE0F2FE), textColor: const Color(0xFF0369A1)),
        SymptomData(label: 'Mild Fever', bgColor: const Color(0xFFFEF3C7), textColor: const Color(0xFFB45309)),
      ],
      aiInsights: 'History of diabetes. Recent joint pains could indicate inflammatory response. Monitor blood sugar levels and markers for rheumatoid factors.',
    );
  }

  static PatientData getDummyAmitabh() {
    return PatientData(
      id: 3, // Dummy ID
      name: 'Amitabh Bachchan',
      age: '78',
      gender: 'Male',
      village: 'Mumbai South, Juhu',
      bloodType: 'B Positive',
      chronicConditions: 'Hypertension, Asthma',
      pastSurgeries: 'Abdominal Surgery (2005)',
      allergies: 'None reported',
      abhaId: 'ABHA-0000-0000',
      symptoms: [
        SymptomData(label: 'Dizziness', bgColor: const Color(0xFFF3E8FF), textColor: const Color(0xFF7E22CE)),
        SymptomData(label: 'Chest Tightness', bgColor: const Color(0xFFFEE2E2), textColor: const Color(0xFFDC2626)),
      ],
      aiInsights: 'Patient is high-risk due to age and respiratory history. Chest tightness requires immediate ECG and vital monitoring.',
    );
  }

  static PatientData getDummySunita() {
    return PatientData(
      id: 4, // Dummy ID
      name: 'Sunita Deshmukh',
      age: '32',
      gender: 'Female',
      village: 'Pelhar, East District',
      bloodType: 'AB Positive',
      chronicConditions: 'None reported',
      pastSurgeries: 'C-Section (2020)',
      allergies: 'Sulfa Drugs',
      abhaId: 'ABHA-9999-8888',
      symptoms: [
        SymptomData(label: 'Headache', bgColor: const Color(0xFFF1F5F9), textColor: const Color(0xFF475569)),
        SymptomData(label: 'Nausea', bgColor: const Color(0xFFECFDF5), textColor: const Color(0xFF059669)),
      ],
      aiInsights: 'Possible migraine or hormonal imbalance. Check blood pressure and stress levels.',
    );
  }
}

class SymptomData {
  final String label;
  final Color bgColor;
  final Color textColor;

  SymptomData({required this.label, required this.bgColor, required this.textColor});
}

class PatientDetailsScreen extends StatefulWidget {
  final PatientData patient;

  const PatientDetailsScreen({super.key, required this.patient});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  late PatientData _currentPatient;
  final DoctorService _doctorService = DoctorService();
  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    _currentPatient = widget.patient;
    _fetchFullProfile();
  }

  Future<void> _fetchFullProfile() async {
    if (_currentPatient.abhaId.isEmpty) return;
    
    setState(() => _isLoadingProfile = true);
    try {
      final fullData = await _doctorService.getPatientFullProfile(_currentPatient.abhaId);
      if (fullData != null && mounted) {
        setState(() {
          _currentPatient = PatientData.fromJson(fullData);
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching full profile: $e');
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF1F2937);
    const backgroundColor = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Patient Details',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            _buildProfileCard(),
            const SizedBox(height: 20),
            _buildActionButtons(context),
            const SizedBox(height: 20),
            if (_isLoadingProfile)
              const Center(child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              )),
            _buildPersonalInfoCard(),
            const SizedBox(height: 20),
            _buildHealthHistoryCard(),
            const SizedBox(height: 20),
            if (_currentPatient.emergencyContact != null) ...[
              _buildEmergencyContactCard(),
              const SizedBox(height: 20),
            ],
            if (_currentPatient.familyMembers != null && _currentPatient.familyMembers!.isNotEmpty) ...[
              _buildFamilyMembersCard(),
              const SizedBox(height: 20),
            ],
            _buildSymptomsCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    const primaryBlue = Color(0xFF2A7DE1);
    const textPrimary = Color(0xFF1F2937);
    const textSecondary = Color(0xFF6B7280);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFFE8F1FF),
            child: Icon(Icons.person, size: 50, color: primaryBlue),
          ),
          const SizedBox(height: 16),
          Text(
            _currentPatient.name,
            style: const TextStyle(
              color: textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _currentPatient.gender,
                  style: const TextStyle(
                    color: primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentPatient.age} years old',
                  style: const TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: textSecondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Village: ${_currentPatient.village}',
                  style: const TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    const primaryBlue = Color(0xFF2A7DE1);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VideoConsultationScreen(
                    consultationId: '', // Should be fixed to actual ID later if needed
                  ),
                ),
              );
            },
            icon: const Icon(Icons.videocam_outlined, size: 20),
            label: const Text(
              'Start Video Consultation',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(
              Icons.phone_outlined,
              size: 20,
              color: primaryBlue,
            ),
            label: const Text(
              'Start Audio Call',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: primaryBlue, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () async {
              try {
                // Start a consultation first
                final doctorService = DoctorService();
                final consultation = await doctorService.startConsultation(
                  patientId: _currentPatient.id,
                  callType: 'OFFLINE',
                );

                if (context.mounted) {
                  final consultationId = consultation['id'];
                  if (consultationId == null) {
                    throw Exception('Failed to get consultation ID from server');
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreatePrescriptionScreen(
                        patientName: _currentPatient.name,
                        consultationId: consultationId.toString(),
                        patientId: _currentPatient.id.toString(),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error starting consultation: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.assignment_outlined, size: 20),
            label: const Text(
              'Create Prescription',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoCard() {
    return _buildCardBase(
      title: 'Personal Info',
      iconUrl: Icons.person_outline,
      child: Column(
        children: [
          _buildInfoRow('Full Name', _currentPatient.name),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildInfoRow('ABHA ID', _currentPatient.abhaId.isEmpty ? 'N/A' : _currentPatient.abhaId),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildInfoRow('Age', _currentPatient.age),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildInfoRow('Location', _currentPatient.village),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildInfoRow('Blood Type', _currentPatient.bloodType),
        ],
      ),
    );
  }

  Widget _buildHealthHistoryCard() {
    return _buildCardBase(
      title: 'Health History',
      iconUrl: Icons.history,
      child: Column(
        children: [
          _buildHistorySection(
            'CHRONIC CONDITIONS',
            _currentPatient.chronicConditions,
          ),
          const SizedBox(height: 12),
          _buildHistorySection('PAST SURGERIES', _currentPatient.pastSurgeries),
          const SizedBox(height: 12),
          _buildHistorySection('ALLERGIES', _currentPatient.allergies),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactCard() {
    final ec = _currentPatient.emergencyContact;
    if (ec == null) return const SizedBox.shrink();
    return _buildCardBase(
      title: 'Emergency Contact',
      iconUrl: Icons.contact_phone_outlined,
      child: Column(
        children: [
          _buildInfoRow('Name', ec['name'] ?? 'N/A'),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildInfoRow('Relation', ec['relationship'] ?? 'N/A'),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildInfoRow('Phone', ec['phone_number'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildFamilyMembersCard() {
    final fm = _currentPatient.familyMembers;
    if (fm == null || fm.isEmpty) return const SizedBox.shrink();
    return _buildCardBase(
      title: 'Family Members',
      iconUrl: Icons.family_restroom,
      child: Column(
        children: fm.map((m) => Column(
          children: [
            _buildInfoRow(m['relationship'] ?? 'Member', m['name'] ?? 'N/A'),
            if (fm.indexOf(m) != fm.length - 1)
              const Divider(height: 24, color: Color(0xFFF1F5F9)),
          ],
        )).toList(),
      ),
    );
  }

  Widget _buildSymptomsCard() {
    return _buildCardBase(
      title: 'Symptoms',
      iconUrl: Icons.medical_services_outlined,
      titleBadge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF2A7DE1).withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'AI ANALYZED',
          style: TextStyle(
            color: Color(0xFF2A7DE1),
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _currentPatient.symptoms.map((s) => _buildSymptomChip(s.label, s.bgColor, s.textColor)).toList(),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 13,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(
                    text: 'AI Insights: ',
                    style: TextStyle(
                      color: Color(0xFF2A7DE1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: _currentPatient.aiInsights,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBase({
    required String title,
    required IconData iconUrl,
    Widget? titleBadge,
    required Widget child,
  }) {
    const primaryBlue = Color(0xFF2A7DE1);
    const textPrimary = Color(0xFF1F2937);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconUrl, color: primaryBlue, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (titleBadge != null) ...[const SizedBox(width: 8), titleBadge],
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection(String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF3B82F6),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
