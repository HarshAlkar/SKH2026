import 'package:flutter/material.dart';
import '../models/consultation_model.dart';
import '../widgets/consultation_form_field.dart';
import '../widgets/consultation_dropdown.dart';
import '../../../core/widgets/common_appbar.dart';
import '../../asha_worker/widgets/asha_drawer.dart';

class RequestConsultationScreen extends StatefulWidget {
  const RequestConsultationScreen({super.key});

  @override
  State<RequestConsultationScreen> createState() => _RequestConsultationScreenState();
}

class _RequestConsultationScreenState extends State<RequestConsultationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _symptomsController = TextEditingController();
  
  String? _selectedPatient = 'Ramesh Patil';
  UrgencyLevel _selectedUrgency = UrgencyLevel.normal;
  ConsultationType _selectedType = ConsultationType.videoCall;
  String? _attachedFileName;
  bool _isLoading = false;

  final List<String> _patients = ['Ramesh Patil', 'Sita Devi', 'Arun Kumar'];

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  void _simulateFileUpload() {
    setState(() {
      _attachedFileName = 'health_record_${DateTime.now().millisecondsSinceEpoch}.pdf';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Attached: $_attachedFileName')),
    );
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Create consultation request object
      final request = ConsultationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        patientName: _selectedPatient!,
        doctorName: 'Pending Assignment', // Will be assigned by system
        symptoms: _symptomsController.text,
        urgency: _selectedUrgency,
        type: _selectedType,
        timestamp: DateTime.now(),
        status: ConsultationStatus.pending,
      );

      // Simulate sending to doctor
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Consultation request sent successfully."),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, request);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2F4DB6);
    const Color backgroundColor = Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const CommonAppBar(
        title: "Request Consultation",
      ),
      drawer: const AshaDrawer(currentRoute: ''), // Not a main drawer route
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Patient Selection
                  ConsultationDropdown<String>(
                    label: "Select Patient",
                    value: _selectedPatient!,
                    icon: Icons.person_outline,
                    items: _patients.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (val) => setState(() => _selectedPatient = val),
                  ),
                  const SizedBox(height: 20),

                  // Symptoms
                  ConsultationFormField(
                    label: "Patient Symptoms",
                    hint: "Describe symptoms reported by the patient.",
                    controller: _symptomsController,
                    maxLines: 4,
                    icon: Icons.note_alt_outlined,
                    validator: (val) => val == null || val.isEmpty ? "Please describe patient symptoms" : null,
                  ),
                  const SizedBox(height: 20),

                  // Urgency Level
                  const Text(
                    "Urgency Level",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<UrgencyLevel>(
                    initialValue: _selectedUrgency,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.emergency_outlined, color: primaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: UrgencyLevel.normal,
                        child: Row(
                          children: [
                            Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            const Text("Normal"),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: UrgencyLevel.moderate,
                        child: Row(
                          children: [
                            Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            const Text("Moderate"),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: UrgencyLevel.urgent,
                        child: Row(
                          children: [
                            Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            const Text("Urgent"),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedUrgency = val!),
                  ),
                  const SizedBox(height: 24),

                  // Consultation Type
                  const Text(
                    "Preferred Consultation Type",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildTypeButton( ConsultationType.videoCall, Icons.videocam_outlined, "Video"),
                      const SizedBox(width: 8),
                      _buildTypeButton( ConsultationType.audioCall, Icons.phone_outlined, "Audio"),
                      const SizedBox(width: 8),
                      _buildTypeButton( ConsultationType.chatMessage, Icons.chat_bubble_outline, "Chat"),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Attach Report
                  OutlinedButton.icon(
                    onPressed: _simulateFileUpload,
                    icon: const Icon(Icons.attachment_outlined),
                    label: Text(_attachedFileName ?? "Attach Health Report (Optional)"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: primaryColor,
                      side: const BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Request Button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleSubmit,
                    icon: const Icon(Icons.medical_services_outlined, color: Colors.white),
                    label: const Text(
                      "Send Consultation Request",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator(color: primaryColor)),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(ConsultationType type, IconData icon, String label) {
    bool isSelected = _selectedType == type;
    const Color primaryColor = Color(0xFF2F4DB6);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey[600]),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
