import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/theme/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../../routes/app_routes.dart';
import '../services/doctor_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final TextEditingController _symptomsController = TextEditingController();
  final DoctorService _doctorService = DoctorService();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;
  bool _speechInitialized = false;
  bool _isAnalyzing = false;
  bool _isBooking = false;
  bool _loadingSlots = false;

  // Step 1: Form state
  final Set<String> _selectedSymptomTokens = {};
  String _selectedSeverity = 'Moderate';
  String _selectedDuration = '1-2 days';

  // Step 2: Result state
  Map<String, dynamic>? _matchResult;
  Map<String, dynamic>? _selectedDoctor;
  String? _selectedDate;
  String? _selectedTime;
  List<String> _currentAvailableSlots = [];
  bool _showCustomPicker = false;

  final List<String> _commonSymptoms = [
    'Fever',
    'Cough / Cold',
    'Skin problem / Rash',
    'Headache',
    'Stomach pain',
    'Breathing difficulty',
    'Child-related concern',
    'Women\'s health / Pregnancy',
    'Bone / Joint pain',
    'Weakness / Dizziness',
    'Other'
  ];

  final List<String> _severities = ['Mild', 'Moderate', 'Severe', 'Emergency'];
  final List<String> _durations = ['Today (< 24 hrs)', '1-2 days', '3-7 days', 'More than 1 week'];

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    if (_isListening) {
      _speech.stop();
    }
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      _speechInitialized = await _speech.initialize(
        onError: (err) {
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
    } catch (_) {
      _speechInitialized = false;
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    if (!_speechInitialized) {
      await _initSpeech();
    }

    if (!_speechInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition is not available. Please type your symptoms.')),
      );
      return;
    }

    setState(() => _isListening = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎤 Listening... Please speak your symptoms in English or Hindi.'),
        duration: Duration(seconds: 4),
      ),
    );

    try {
      await _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            setState(() {
              _symptomsController.text = result.recognizedWords;
            });
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
      );
    } catch (_) {
      setState(() => _isListening = false);
    }
  }

  void _toggleSymptomChip(String symptom) {
    if (symptom == 'Other') return;
    setState(() {
      if (_selectedSymptomTokens.contains(symptom)) {
        _selectedSymptomTokens.remove(symptom);
      } else {
        _selectedSymptomTokens.add(symptom);
      }

      // Sync with text controller
      final customText = _symptomsController.text.trim();
      final chipsText = _selectedSymptomTokens.join(', ');
      if (customText.isEmpty || _commonSymptoms.any((s) => customText.contains(s))) {
        _symptomsController.text = chipsText;
      }
    });
  }

  void _showError(String rawError) {
    String message = 'Something went wrong on the server. Please try again.';
    final lowerError = rawError.toLowerCase();

    if (lowerError.contains('socketexception') ||
        lowerError.contains('timeout') ||
        lowerError.contains('network') ||
        lowerError.contains('failed host lookup') ||
        lowerError.contains('clientexception')) {
      message = 'Unable to connect to server.\nYour appointment request can be saved offline.';
    } else if (lowerError.contains('unauthorized') || lowerError.contains('token')) {
      message = 'Your session has expired. Please log in again.';
    } else if (lowerError.contains('slot') ||
        lowerError.contains('conflict') ||
        lowerError.contains('no longer available')) {
      message = 'This appointment slot is no longer available. Please choose another available time.';
    } else if (lowerError.contains('doctor') && lowerError.contains('not find')) {
      message = 'We could not find an available doctor at this moment. Please try again shortly.';
    } else if (rawError.replaceAll('Exception: ', '').trim().isNotEmpty &&
        !lowerError.contains('server error')) {
      message = rawError.replaceAll('Exception: ', '');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitSymptoms() async {
    final text = _symptomsController.text.trim();
    if (text.isEmpty && _selectedSymptomTokens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or describe what you are experiencing.')),
      );
      return;
    }

    final combinedSymptoms = text.isNotEmpty
        ? text
        : _selectedSymptomTokens.join(', ');

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    }

    setState(() {
      _isAnalyzing = true;
      _matchResult = null;
      _selectedDoctor = null;
      _selectedDate = null;
      _selectedTime = null;
      _showCustomPicker = false;
    });

    try {
      final result = await _doctorService.smartMatch(
        symptoms: combinedSymptoms,
        duration: _selectedDuration,
        severity: _selectedSeverity,
      );

      if (mounted) {
        setState(() {
          _matchResult = result;
          _selectedDoctor = result['recommended_doctor'] is Map
              ? Map<String, dynamic>.from(result['recommended_doctor'])
              : null;
          _selectedDate = result['recommended_date']?.toString();
          _selectedTime = result['recommended_time']?.toString();
          _currentAvailableSlots = List<String>.from(result['alternative_times'] ?? []);
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        _showError(e.toString());
      }
    }
  }

  Future<void> _onDateChanged(String newDate) async {
    setState(() {
      _selectedDate = newDate;
      _loadingSlots = true;
    });

    if (_selectedDoctor != null) {
      final docId = _selectedDoctor!['id'] ?? 0;
      final slots = await _doctorService.getDoctorSlots(doctorId: docId, date: newDate);
      if (mounted) {
        setState(() {
          _currentAvailableSlots = slots;
          if (!slots.contains(_selectedTime)) {
            _selectedTime = slots.isNotEmpty ? slots.first : '10:30:00';
          }
          _loadingSlots = false;
        });
      }
    } else {
      setState(() => _loadingSlots = false);
    }
  }

  void _onDoctorChanged(Map<String, dynamic> doctor) {
    setState(() {
      _selectedDoctor = doctor;
      _showCustomPicker = true;
    });
    if (_selectedDate != null) {
      _onDateChanged(_selectedDate!);
    }
  }

  Future<void> _confirmAppointment() async {
    if (_selectedDoctor == null || _selectedDate == null || _selectedTime == null) return;

    setState(() => _isBooking = true);
    try {
      final doctorId = _selectedDoctor!['id'] ?? 0;
      final type = _matchResult?['recommended_type'] ?? 'VIDEO';
      final symptoms = _matchResult?['symptoms_analyzed'] ?? _symptomsController.text.trim();
      final doctorName = _selectedDoctor!['name'] ?? 'Doctor';
      final specialty = _selectedDoctor!['specialization'] ?? _matchResult?['recommended_specialization'] ?? 'General Physician';

      final response = await _doctorService.bookAppointment(
        doctorId: doctorId,
        date: _selectedDate!,
        time: _selectedTime!,
        type: type,
        notes: symptoms,
      );

      if (mounted) {
        setState(() => _isBooking = false);
        if (response.containsKey('error') && response['error'] != null) {
          final err = response['error'].toString();
          _showError(err);
          // Refresh slots to remove occupied time
          if (_selectedDate != null) {
            _onDateChanged(_selectedDate!);
          }
        } else {
          // Schedule reminder and show instant local notification
          final appointmentId = response['id'] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
          try {
            await NotificationService().showAppointmentConfirmation(
              doctorName: doctorName,
              date: _selectedDate!,
              time: _selectedTime!,
              specialty: specialty,
            );

            // Attempt parsing appointment time for calendar reminder
            final parsedDt = DateTime.tryParse('$_selectedDate ${_selectedTime!}');
            if (parsedDt != null) {
              await NotificationService().scheduleAppointmentReminder(
                appointmentId: appointmentId is int ? appointmentId : 101,
                appointmentDateTime: parsedDt,
                doctorName: doctorName,
                specialty: specialty,
              );
            }
          } catch (_) {}

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment booked successfully.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBooking = false);
        _showError(e.toString());
      }
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('EEEE, MMM dd').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatTime(String timeStr) {
    try {
      if (timeStr.length >= 5) {
        final parts = timeStr.split(':');
        final t = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        return t.format(context);
      }
    } catch (_) {}
    return timeStr;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Book Appointment',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _matchResult == null ? _buildSymptomInputScreen() : _buildRecommendationScreen(),
      ),
    );
  }

  Widget _buildSymptomInputScreen() {
    final isEmergency = _selectedSeverity == 'Emergency';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What are you experiencing?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Text(
            'Select your symptoms or describe how you are feeling in simple words.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),

          // Symptom selection chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _commonSymptoms.map((symptom) {
              final isSelected = _selectedSymptomTokens.contains(symptom);
              return FilterChip(
                label: Text(symptom),
                selected: isSelected,
                selectedColor: AppColors.lightBlue,
                checkmarkColor: AppColors.primary,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : const Color(0xFF334155),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : Colors.grey.shade300,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                onSelected: (_) => _toggleSymptomChip(symptom),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Free text & voice input field
          TextField(
            controller: _symptomsController,
            maxLines: 3,
            style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: 'Describe your symptoms (e.g. fever and severe cough since 2 days)...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _toggleListening,
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? Colors.white : AppColors.primary,
                size: 18,
              ),
              label: Text(
                _isListening ? 'Listening...' : 'Speak your problem',
                style: TextStyle(
                  color: _isListening ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isListening ? Colors.red : AppColors.lightBlue,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Severity Selector
          const Text(
            'How severe are your symptoms?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),
          Row(
            children: _severities.map((sev) {
              final isSelected = _selectedSeverity == sev;
              Color color;
              if (sev == 'Mild') color = Colors.green;
              else if (sev == 'Moderate') color = Colors.orange;
              else if (sev == 'Severe') color = Colors.deepOrange;
              else color = Colors.red;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () => setState(() => _selectedSeverity = sev),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.12) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? color : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            sev == 'Emergency' ? Icons.warning_amber_rounded : Icons.lens,
                            color: isSelected ? color : Colors.grey.shade400,
                            size: 14,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sev,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? color : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Duration Selector
          const Text(
            'How long have you had these symptoms?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _durations.map((dur) {
              final isSelected = _selectedDuration == dur;
              return ChoiceChip(
                label: Text(dur),
                selected: isSelected,
                selectedColor: AppColors.lightBlue,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : const Color(0xFF475569),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  ),
                ),
                onSelected: (selected) {
                  if (selected) setState(() => _selectedDuration = dur);
                },
              );
            }).toList(),
          ),

          // Emergency Escalation Banner
          if (isEmergency) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emergency, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Immediate Medical Attention Required',
                        style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'If you are experiencing severe chest pain, shortness of breath, or trauma, do not wait for a scheduled appointment.',
                    style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.emergencyHelp),
                        icon: const Icon(Icons.call, size: 14, color: Colors.white),
                        label: const Text('Emergency Help', style: TextStyle(fontSize: 12, color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.ashaWorkers),
                        icon: const Icon(Icons.health_and_safety, size: 14, color: Colors.red),
                        label: const Text('Call ASHA', style: TextStyle(fontSize: 12, color: Colors.red)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          // Disclaimer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Preliminary screening & triage only. This is not a medical diagnosis.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isAnalyzing ? null : _submitSymptoms,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: _isAnalyzing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('Finding appropriate care...', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    )
                  : const Text('Find the Right Care', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationScreen() {
    final docData = _selectedDoctor ?? {};
    final doctorName = docData['name'] ?? 'Doctor';
    final hospitalName = docData['hospital_name'] ?? 'Kopargaon Rural Hospital';
    final specialty = docData['specialization'] ?? _matchResult?['recommended_specialization'] ?? 'General Physician';
    final reason = _matchResult?['recommendation_reason'] ?? 'Recommended specialist based on your symptom analysis.';
    final type = _matchResult?['recommended_type'] ?? 'VIDEO';
    final urgency = _matchResult?['urgency'] ?? 'MODERATE';

    final List<String> altDates = List<String>.from(_matchResult?['alternative_dates'] ?? []);
    final List<dynamic> otherDocs = _matchResult?['other_doctors'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommended Appointment',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            'Matched specialist for your condition',
            style: TextStyle(fontSize: 14, color: Colors.green.shade700, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // Triage reason card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightBlue.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.medical_services_outlined, color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recommended Specialty: $specialty',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reason,
                        style: const TextStyle(color: Color(0xFF334155), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Matched Doctor Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.lightBlue,
                  radius: 26,
                  child: const Icon(Icons.person, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doctorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text(specialty, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(hospitalName, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    type == 'VIDEO' ? 'Video' : (type == 'AUDIO' ? 'Audio' : 'In-Person'),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Recommended Slot Card
          if (!_showCustomPicker) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade300, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Earliest Recommended Slot',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(_formatDate(_selectedDate ?? ''), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const Spacer(),
                      Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(_formatTime(_selectedTime ?? ''), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isBooking ? null : _confirmAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isBooking
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Book Recommended Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _showCustomPicker = true),
                icon: const Icon(Icons.edit_calendar, size: 16, color: AppColors.primary),
                label: const Text('Don\'t like this time? Choose another slot', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ),
          ] else ...[
            // Custom Date & Time Picker
            const Text('Choose Appointment Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: altDates.map((d) {
                final isSelected = _selectedDate == d;
                return ChoiceChip(
                  label: Text(_formatDate(d)),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF1E293B),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade300),
                  ),
                  onSelected: (selected) {
                    if (selected) _onDateChanged(d);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            const Text('Choose Available Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
            const SizedBox(height: 10),
            if (_loadingSlots)
              const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()))
            else if (_currentAvailableSlots.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text('No available slots on this date. Please choose another date.', style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _currentAvailableSlots.map((t) {
                  final isSelected = _selectedTime == t;
                  return ChoiceChip(
                    label: Text(_formatTime(t)),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF1E293B),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade300),
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedTime = t);
                    },
                  );
                }).toList(),
              ),

            if (otherDocs.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Or Select Another Suitable Doctor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF475569))),
              const SizedBox(height: 8),
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: otherDocs.length,
                  itemBuilder: (context, idx) {
                    final odoc = Map<String, dynamic>.from(otherDocs[idx]);
                    final isCur = _selectedDoctor?['id'] == odoc['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: CircleAvatar(
                          backgroundColor: isCur ? AppColors.primary : AppColors.lightBlue,
                          child: Icon(Icons.person, size: 14, color: isCur ? Colors.white : AppColors.primary),
                        ),
                        label: Text(odoc['name'] ?? 'Doctor'),
                        backgroundColor: isCur ? AppColors.lightBlue : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: isCur ? AppColors.primary : Colors.grey.shade300),
                        ),
                        onPressed: () => _onDoctorChanged(odoc),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_isBooking || _selectedDate == null || _selectedTime == null) ? null : _confirmAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: _isBooking
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                          SizedBox(width: 10),
                          Text('Booking appointment...', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      )
                    : const Text('Confirm Appointment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _isBooking ? null : () => setState(() => _matchResult = null),
              child: const Text('Edit Symptoms / Go Back', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
