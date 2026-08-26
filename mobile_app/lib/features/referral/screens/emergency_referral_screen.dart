import 'package:flutter/material.dart';
import '../../../core/sync/offline_api.dart';
import '../../asha_worker/widgets/asha_sidebar.dart';

class EmergencyReferralScreen extends StatefulWidget {
  const EmergencyReferralScreen({super.key});

  @override
  State<EmergencyReferralScreen> createState() =>
      _EmergencyReferralScreenState();
}

class _EmergencyReferralScreenState extends State<EmergencyReferralScreen> {
  final OfflineApi _api = OfflineApi.instance;
  final _symptoms = TextEditingController();
  final _notes = TextEditingController();
  List<Map<String, dynamic>> _patients = [];
  int? _patientId;
  String _severity = 'moderate';
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _symptoms.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final response = await _api.get('/patients/');
      final rows = response is List ? response : <dynamic>[];
      final patients = <Map<String, dynamic>>[];
      for (final row in rows) {
        if (row is! Map) continue;
        final map = Map<String, dynamic>.from(row);
        final id = int.tryParse(map['id']?.toString() ?? '');
        if (id == null) continue;
        patients.add({'id': id, 'name': map['name'] ?? 'Patient $id'});
      }
      if (!mounted) return;
      setState(() {
        _patients = patients;
        _patientId = patients.isNotEmpty ? patients.first['id'] as int : null;
        _loading = false;
        _loadError = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'Could not load patients. Tap retry.';
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_patientId == null) return;
    setState(() => _saving = true);
    try {
      final result = await _api.post('/alerts/referrals/', body: {
        'patient': _patientId,
        'symptoms': _symptoms.text.trim(),
        'severity': _severity,
        'notes': _notes.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.synced ? Colors.green : Colors.orange,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AshaSidebar(),
      appBar: AppBar(
        title: const Text(
          'Emergency Referral',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2F4DB6),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_loadError!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadPatients,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
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
                      onChanged: (v) => setState(() => _patientId = v),
                      decoration: const InputDecoration(labelText: 'Patient'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _severity,
                      items: const [
                        DropdownMenuItem(value: 'normal', child: Text('Normal')),
                        DropdownMenuItem(
                          value: 'moderate',
                          child: Text('Moderate'),
                        ),
                        DropdownMenuItem(
                          value: 'critical',
                          child: Text('Critical'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _severity = v);
                      },
                      decoration: const InputDecoration(labelText: 'Severity'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _symptoms,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Symptoms'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notes,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Notes'),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: (_saving || _patientId == null) ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(_saving ? 'Sending...' : 'Send referral'),
                    ),
                  ],
                ),
    );
  }
}
