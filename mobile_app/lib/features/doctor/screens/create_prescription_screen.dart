import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/user/services/doctor_service.dart';
import '../../../models/medicine_model.dart';
import '../../../providers/consultation_provider.dart';

class CreatePrescriptionScreen extends StatefulWidget {
  final String? patientName;
  final String? consultationId;
  const CreatePrescriptionScreen({super.key, this.patientName, this.consultationId});

  @override
  State<CreatePrescriptionScreen> createState() => _CreatePrescriptionScreenState();
}

class _CreatePrescriptionScreenState extends State<CreatePrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _patientNameController;
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();
  final _medicineNameController = TextEditingController();
  final _purposeController = TextEditingController();
  final _dosageController = TextEditingController();
  final _routeController = TextEditingController();
  final _durationController = TextEditingController();
  final _instructionsController = TextEditingController();
  
  final DoctorService _doctorService = DoctorService();
  bool _isSaving = false;

  final List<String> _timingOptions = ['Before Breakfast', 'After Meals', 'At Bedtime'];
  final Set<String> _selectedTimings = {};

  final Color primaryBlue = const Color(0xFF2A7DE1);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);
  final Color borderColor = const Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _patientNameController = TextEditingController(text: widget.patientName ?? 'Sarah Jenkins');
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _diagnosisController.dispose();
    _notesController.dispose();
    _medicineNameController.dispose();
    _purposeController.dispose();
    _dosageController.dispose();
    _routeController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _generatePrescription() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (context) => _buildPrescriptionSummaryDialog(),
      );
    }
  }

  Widget _buildPrescriptionSummaryDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.description, color: primaryBlue, size: 24),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Prescription',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSummaryRow('PATIENT', _patientNameController.text.toUpperCase()),
            const Divider(height: 24),
            Text(
              'Rx',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('MEDICINE', _medicineNameController.text),
            _buildSummaryRow('DOSAGE', _dosageController.text),
            _buildSummaryRow('DURATION', _durationController.text),
            const SizedBox(height: 12),
            Text(
              'INSTRUCTIONS',
              style: TextStyle(
                color: textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _instructionsController.text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            if (_selectedTimings.isNotEmpty)
              Wrap(
                spacing: 8,
                children: _selectedTimings.map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    t,
                    style: TextStyle(color: primaryBlue, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                )).toList(),
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () async {
                  setState(() => _isSaving = true);
                  
                  try {
                    final consultationId = widget.consultationId;
                    if (consultationId == null) {
                      throw Exception('Consultation ID is missing. Cannot save prescription.');
                    }
                    
                    final prescriptionData = {
                      'consultation': int.tryParse(consultationId),
                      'diagnosis': _diagnosisController.text,
                      'notes': _notesController.text,
                      'medications': [
                        {
                          'name': _medicineNameController.text,
                          'purpose': _purposeController.text,
                          'dosage': _dosageController.text,
                          'route': _routeController.text.isEmpty ? 'Oral' : _routeController.text,
                          'duration': _durationController.text,
                          'instructions': _instructionsController.text,
                          'timing': _selectedTimings.join(', '),
                        }
                      ],
                    };
                    
                    await _doctorService.createPrescription(prescriptionData);
                    
                    if (mounted) {
                      // Refresh consultation history
                      context.read<ConsultationProvider>().fetchHistory();
                      
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Back to previous screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Prescription Saved & Sent to Database'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error saving prescription: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isSaving = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Confirm & Send', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Prescription',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(Icons.person_outline, 'PATIENT INFORMATION'),
              const SizedBox(height: 12),
              _buildPatientInfoCard(),
              const SizedBox(height: 32),
              
              _buildLabel('Diagnosis'),
              _buildTextField(
                controller: _diagnosisController,
                placeholder: 'Enter diagnosis',
                validatorError: 'Please enter diagnosis',
              ),
              const SizedBox(height: 16),
              
              _buildLabel('Notes'),
              _buildTextField(
                controller: _notesController,
                placeholder: 'Additional notes',
                validatorError: 'Required',
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              
              _buildSectionTitle(Icons.add_box_outlined, 'MEDICATION DETAILS'),
              const SizedBox(height: 16),
              
              _buildLabel('Medicine Name'),
              _buildTextField(
                controller: _medicineNameController,
                placeholder: 'e.g. Amoxicillin',
                validatorError: 'Please enter medicine name',
              ),
              const SizedBox(height: 16),
              
              _buildLabel('Purpose'),
              _buildTextField(
                controller: _purposeController,
                placeholder: 'e.g. Bacterial infection',
                validatorError: 'Please enter purpose',
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Dosage'),
                        _buildTextField(
                          controller: _dosageController,
                          placeholder: 'e.g. 500mg',
                          validatorError: 'Required',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Route'),
                        _buildTextField(
                          controller: _routeController,
                          placeholder: 'e.g. Oral',
                          validatorError: 'Required',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildLabel('Duration'),
              _buildTextField(
                controller: _durationController,
                placeholder: 'e.g. 7 days',
                validatorError: 'Required',
              ),
              const SizedBox(height: 16),
              
              _buildLabel('Instructions'),
              _buildTextField(
                controller: _instructionsController,
                placeholder: 'e.g. Take twice daily after meals',
                validatorError: 'Please enter instructions',
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              
              _buildTimingTags(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generatePrescription,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: primaryBlue.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.print_outlined, size: 22),
              label: const Text(
                'Generate Prescription',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: primaryBlue, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPatientInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBF1F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Patient Name'),
          _buildTextField(
            controller: _patientNameController,
            placeholder: 'Enter patient name',
            validatorError: 'Please enter patient name',
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Date',
                style: TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Text(
                'Mar 14, 2026',
                style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    required String validatorError,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return validatorError;
        }
        return null;
      },
    );
  }

  Widget _buildTimingTags() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _timingOptions.map((timing) {
        final isSelected = _selectedTimings.contains(timing);
        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedTimings.remove(timing);
              } else {
                _selectedTimings.add(timing);
              }
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? primaryBlue.withOpacity(0.08) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? primaryBlue.withOpacity(0.3) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              timing,
              style: TextStyle(
                color: isSelected ? primaryBlue : const Color(0xFF475569),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
