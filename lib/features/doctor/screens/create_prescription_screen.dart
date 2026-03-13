import 'package:flutter/material.dart';

class CreatePrescriptionScreen extends StatefulWidget {
  const CreatePrescriptionScreen({super.key});

  @override
  State<CreatePrescriptionScreen> createState() => _CreatePrescriptionScreenState();
}

class _CreatePrescriptionScreenState extends State<CreatePrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _medicineNameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _durationController = TextEditingController();
  final _instructionsController = TextEditingController();

  final List<String> _timingOptions = ['Before Breakfast', 'After Meals', 'At Bedtime'];
  final Set<String> _selectedTimings = {};

  final Color primaryBlue = const Color(0xFF2A7DE1);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);
  final Color borderColor = const Color(0xFFE2E8F0);

  @override
  void dispose() {
    _medicineNameController.dispose();
    _dosageController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _generatePrescription() {
    if (_formKey.currentState!.validate()) {
      // Logic to save the prescription
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Prescription Generated Successfully'),
          backgroundColor: primaryBlue,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
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
              
              _buildSectionTitle(Icons.add_box_outlined, 'MEDICATION DETAILS'),
              const SizedBox(height: 16),
              
              _buildLabel('Medicine Name'),
              _buildTextField(
                controller: _medicineNameController,
                placeholder: 'e.g. Amoxicillin',
                validatorError: 'Please enter medicine name',
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
                        _buildLabel('Duration'),
                        _buildTextField(
                          controller: _durationController,
                          placeholder: 'e.g. 7 days',
                          validatorError: 'Required',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildLabel('Instructions'),
              _buildTextField(
                controller: _instructionsController,
                placeholder: 'e.g. Take twice daily after meals',
                validatorError: 'Please enter instructions',
                maxLines: 4,
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FB), // Very light soft blue/grey matching reference #E8F1FF tone
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBF1F6)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Patient Name',
                style: TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Text(
                'John Doe',
                style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Date',
                style: TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Text(
                'Oct 24, 2023',
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
