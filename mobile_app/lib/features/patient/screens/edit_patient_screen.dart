import 'package:flutter/material.dart';
import '../models/patient_model.dart';
import '../../../core/services/api_service.dart';

class EditPatientScreen extends StatefulWidget {
  final PatientModel patient;
  const EditPatientScreen({super.key, required this.patient});

  @override
  State<EditPatientScreen> createState() => _EditPatientScreenState();
}

class _EditPatientScreenState extends State<EditPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _village;
  late final TextEditingController _gender;
  late final TextEditingController _blood;
  late final TextEditingController _address;
  late final TextEditingController _history;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.patient.name);
    _age = TextEditingController(text: widget.patient.age.toString());
    _village = TextEditingController(text: widget.patient.village);
    _gender = TextEditingController(text: widget.patient.gender);
    _blood = TextEditingController(text: widget.patient.bloodGroup);
    _address = TextEditingController(text: widget.patient.address);
    _history = TextEditingController(text: widget.patient.medicalHistory);
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _village.dispose();
    _gender.dispose();
    _blood.dispose();
    _address.dispose();
    _history.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final pk = widget.patient.patientId;
    if (pk == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing patient profile id')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService().put('/patients/$pk/', body: {
        'name': _name.text.trim(),
        'age': int.tryParse(_age.text.trim()) ?? widget.patient.age,
        'village': _village.text.trim(),
        'gender': _gender.text.trim(),
        'blood_group': _blood.text.trim(),
        'address': _address.text.trim(),
        'medical_history': _history.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Patient', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2F4DB6),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
            TextFormField(controller: _age, decoration: const InputDecoration(labelText: 'Age'), keyboardType: TextInputType.number),
            TextFormField(controller: _village, decoration: const InputDecoration(labelText: 'Village')),
            TextFormField(controller: _gender, decoration: const InputDecoration(labelText: 'Gender')),
            TextFormField(controller: _blood, decoration: const InputDecoration(labelText: 'Blood group')),
            TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'Address')),
            TextFormField(controller: _history, decoration: const InputDecoration(labelText: 'Medical history'), maxLines: 3),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F4DB6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(_saving ? 'Saving...' : 'Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
