import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/sync/offline_api.dart';

class ScheduleVisitScreen extends StatefulWidget {
  const ScheduleVisitScreen({super.key});

  @override
  State<ScheduleVisitScreen> createState() => _ScheduleVisitScreenState();
}

class _ScheduleVisitScreenState extends State<ScheduleVisitScreen> {
  final OfflineApi _api = OfflineApi.instance;
  final _notes = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 30);
  List<Map<String, dynamic>> _patients = [];
  int? _patientId;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
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
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_patientId == null) return;
    setState(() => _saving = true);
    try {
      await _api.post('/asha/visits/', body: {
        'patient': _patientId,
        'visit_date': DateFormat('yyyy-MM-dd').format(_date),
        'visit_time':
            '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}:00',
        'notes': _notes.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not schedule: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule New Visit', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2F4DB6),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
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
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Date: ${DateFormat('dd MMM yyyy').format(_date)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Time: ${_time.format(context)}'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: _time);
                      if (picked != null) setState(() => _time = picked);
                    },
                  ),
                  TextField(
                    controller: _notes,
                    decoration: const InputDecoration(labelText: 'Notes'),
                    maxLines: 3,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F4DB6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(_saving ? 'Saving...' : 'Schedule visit'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
