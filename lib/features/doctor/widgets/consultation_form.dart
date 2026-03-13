import 'package:flutter/material.dart';
import '../models/consultation_model.dart';

class ConsultationForm extends StatefulWidget {
  final Function(ConsultationModel) onSubmit;

  const ConsultationForm({super.key, required this.onSubmit});

  @override
  State<ConsultationForm> createState() => _ConsultationFormState();
}

class _ConsultationFormState extends State<ConsultationForm> {
  final _formKey = GlobalKey<FormState>();
  final _symptomsController = TextEditingController();

  UrgencyLevel _selectedUrgency = UrgencyLevel.normal;
  ConsultationType _selectedType = ConsultationType.video;
  String? _attachedFileName;
  bool _isLoading = false;

  final Color primaryColor = const Color(0xFF2F4DB6);

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  void _simulateFileUpload() {
    setState(() {
      _attachedFileName = "patient_health_report_2024.pdf";
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Report attached successfully")),
    );
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      final newRequest = ConsultationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        doctorName: "Dr. Sharma", // Simulated assignment
        symptoms: _symptomsController.text,
        urgencyLevel: _selectedUrgency,
        consultationType: _selectedType,
        status: ConsultationStatus.pending,
        timestamp: DateTime.now(),
        attachedFileName: _attachedFileName,
      );

      widget.onSubmit(newRequest);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _symptomsController.clear();
          _attachedFileName = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Consultation request sent successfully."),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "NEW CONSULTATION REQUEST",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 20),

            // Symptoms Field
            TextFormField(
              controller: _symptomsController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Describe patient symptoms in detail...",
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.description_outlined, size: 20),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? "Please describe symptoms"
                  : null,
            ),
            const SizedBox(height: 20),

            // Urgency Drodown
            DropdownButtonFormField<UrgencyLevel>(
              value: _selectedUrgency,
              decoration: InputDecoration(
                labelText: "Urgency Level",
                prefixIcon: const Icon(Icons.priority_high),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              items: UrgencyLevel.values.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(
                    level.name[0].toUpperCase() + level.name.substring(1),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedUrgency = val);
              },
            ),
            const SizedBox(height: 20),

            // Consultation Type (Segmented-like buttons)
            const Text(
              "Preferred Consultation Type",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildTypeButton(
                  ConsultationType.video,
                  Icons.video_call_outlined,
                  "Video",
                ),
                const SizedBox(width: 12),
                _buildTypeButton(
                  ConsultationType.audio,
                  Icons.phone_callback_outlined,
                  "Audio",
                ),
                const SizedBox(width: 12),
                _buildTypeButton(
                  ConsultationType.chat,
                  Icons.chat_bubble_outline,
                  "Chat",
                ),
              ],
            ),
            const SizedBox(height: 20),

            // File Upload
            InkWell(
              onTap: _simulateFileUpload,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: primaryColor, width: 1),
                  borderRadius: BorderRadius.circular(12),
                  color: primaryColor.withOpacity(0.02),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _attachedFileName == null
                          ? Icons.attach_file
                          : Icons.check_circle,
                      color: primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _attachedFileName ?? "Attach Health Report (Optional)",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Request Doctor Consultation",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(ConsultationType type, IconData icon, String label) {
    bool isSelected = _selectedType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedType = type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 24,
              ),
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
