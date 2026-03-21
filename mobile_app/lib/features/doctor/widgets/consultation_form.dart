import 'package:flutter/material.dart';
import '../models/consultation_model.dart';

class ConsultationForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;

  const ConsultationForm({super.key, required this.onSubmit});

  @override
  State<ConsultationForm> createState() => _ConsultationFormState();
}

class _ConsultationFormState extends State<ConsultationForm> {
  final _formKey = GlobalKey<FormState>();
  final _symptomsController = TextEditingController();

  UrgencyLevel _urgency = UrgencyLevel.normal;
  ConsultationType _type = ConsultationType.videoCall;

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2F4DB6);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Symptoms Field
          const Text(
            "Patient Symptoms",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _symptomsController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Describe symptoms reported by the patient.",
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: Icon(Icons.note_alt_outlined, color: primaryColor),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please describe patient symptoms";
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Urgency Level Dropdown
          const Text(
            "Urgency Level",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<UrgencyLevel>(
            initialValue: _urgency,
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.emergency_outlined,
                color: primaryColor,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: UrgencyLevel.normal,
                child: Text("Normal"),
              ),
              DropdownMenuItem(
                value: UrgencyLevel.moderate,
                child: Text("Moderate"),
              ),
              DropdownMenuItem(
                value: UrgencyLevel.urgent,
                child: Text("Urgent"),
              ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _urgency = value);
            },
          ),
          const SizedBox(height: 20),

          // Consultation Type (Radio Buttons)
          const Text(
            "Preferred Consultation Type",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTypeRadio(
                ConsultationType.videoCall,
                Icons.videocam_outlined,
                "Video",
              ),
              const SizedBox(width: 8),
              _buildTypeRadio(
                ConsultationType.audioCall,
                Icons.phone_outlined,
                "Audio",
              ),
              const SizedBox(width: 8),
              _buildTypeRadio(
                ConsultationType.chatMessage,
                Icons.chat_bubble_outline,
                "Chat",
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Optional Attach Button
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.attachment_outlined, size: 18),
            label: const Text("Attach Health Report (Optional)"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: primaryColor.withOpacity(0.5)),
              foregroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button
          ElevatedButton.icon(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                widget.onSubmit({
                  "symptoms": _symptomsController.text,
                  "urgency": _urgency,
                  "type": _type,
                });
              }
            },
            icon: const Icon(Icons.video_call, color: Colors.white),
            label: const Text(
              "Request Doctor Consultation",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeRadio(ConsultationType type, IconData icon, String label) {
    const Color primaryColor = Color(0xFF2F4DB6);
    final isSelected = _type == type;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = type),
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
                color: isSelected ? Colors.white : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
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
