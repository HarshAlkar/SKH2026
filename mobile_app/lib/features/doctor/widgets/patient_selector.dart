import 'package:flutter/material.dart';

class PatientSelector extends StatefulWidget {
  final Function(String) onPatientSelected;

  const PatientSelector({super.key, required this.onPatientSelected});

  @override
  State<PatientSelector> createState() => _PatientSelectorState();
}

class _PatientSelectorState extends State<PatientSelector> {
  String? _selectedPatient;

  // Mock patient list
  final List<Map<String, String>> _patients = [
    {"name": "Ramesh Patil", "age": "45", "village": "Kaman"},
    {"name": "Sita Devi", "age": "38", "village": "Rampur"},
    {"name": "Arjun Kumar", "age": "29", "village": "Vikhroli"},
    {"name": "Shanti Devi", "age": "62", "village": "Kaman"},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Patient",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPatient,
              hint: const Text(
                "Search patient...",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              isExpanded: true,
              icon: const Icon(Icons.search, color: Colors.grey),
              items: _patients.map((patient) {
                return DropdownMenuItem<String>(
                  value: patient['name'],
                  child: Text(
                    "${patient['name']} – Age ${patient['age']} – ${patient['village']}",
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPatient = value;
                });
                if (value != null) {
                  widget.onPatientSelected(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
