import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class CreateAlertScreen extends StatefulWidget {
  const CreateAlertScreen({super.key});

  @override
  State<CreateAlertScreen> createState() => _CreateAlertScreenState();
}

class _CreateAlertScreenState extends State<CreateAlertScreen> {
  final ApiService _api = ApiService();
  final _diseaseController = TextEditingController();
  String _severity = 'Moderate';
  List<Map<String, dynamic>> _patients = [];
  int? _patientId;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _diseaseController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    try {
      final response = await _api.get('/users/patients/');
      final rows = response is List ? response : <dynamic>[];
      final patients = <Map<String, dynamic>>[];
      for (final row in rows) {
        if (row is! Map) continue;
        final map = Map<String, dynamic>.from(row);
        final userId = int.tryParse(map['id']?.toString() ?? '');
        if (userId == null) continue;
        patients.add({
          'id': userId,
          'name': map['name'] ?? map['username'] ?? 'Patient $userId',
        });
      }
      if (!mounted) return;
      setState(() {
        _patients = patients;
        _patientId = patients.isNotEmpty ? patients.first['id'] as int : null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a village patient first')),
      );
      return;
    }
    final disease = _diseaseController.text.trim();
    if (disease.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the condition or alert reason')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _api.post('/alerts/notifications/', body: {
        'patient_id': _patientId,
        'disease': disease,
        'severity': _severity,
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create alert: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Manual Alert',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2F4DB6),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _patientId,
                    items: _patients
                        .map(
                          (p) => DropdownMenuItem<int>(
                            value: p['id'] as int,
                            child: Text(p['name'].toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _patientId = value),
                    decoration: const InputDecoration(
                      labelText: 'Village patient',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _diseaseController,
                    decoration: const InputDecoration(
                      labelText: 'Condition / reason',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _severity,
                    items: const [
                      DropdownMenuItem(value: 'Low', child: Text('Low')),
                      DropdownMenuItem(value: 'Moderate', child: Text('Moderate')),
                      DropdownMenuItem(value: 'High', child: Text('High')),
                      DropdownMenuItem(value: 'Critical', child: Text('Critical')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _severity = value);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Severity',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F4DB6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(_saving ? 'Saving...' : 'Send to care team'),
                  ),
                ],
              ),
            ),
    );
  }
}
