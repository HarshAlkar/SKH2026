import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/theme/app_colors.dart';
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
  Map<String, dynamic>? _matchResult;

  String? _selectedDate;
  String? _selectedTime;

  final List<String> _commonSymptoms = [
    'Fever',
    'Cough',
    'Pain',
    'Weakness',
    'Breathing Problem',
    'Stomach Problem',
    'Headache',
    'Skin Problem',
    'Other'
  ];

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
        content: Text('🎤 Listening... Please describe what is happening to you.'),
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

  void _addSymptom(String symptom) {
    if (symptom == 'Other') {
      return;
    }
    final currentText = _symptomsController.text.trim();
    if (currentText.isEmpty) {
      _symptomsController.text = symptom;
    } else if (!currentText.toLowerCase().contains(symptom.toLowerCase())) {
      _symptomsController.text = '$currentText, $symptom';
    }
  }

  void _showError(String rawError) {
    String message = 'Something went wrong on the server. Please try again.';
    final lowerError = rawError.toLowerCase();

    if (lowerError.contains('socketexception') ||
        lowerError.contains('timeout') ||
        lowerError.contains('network') ||
        lowerError.contains('failed host lookup') ||
        lowerError.contains('clientexception')) {
      message = 'Unable to connect.\nPlease check your internet connection and try again.';
    } else if (lowerError.contains('unauthorized') || lowerError.contains('token')) {
      message = 'Your session has expired.\nPlease log in again.';
    } else if (lowerError.contains('slot') ||
        lowerError.contains('conflict') ||
        lowerError.contains('no longer available')) {
      message = 'This appointment slot is no longer available.\nPlease choose another available time.';
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
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe what is happening to you.')),
      );
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    }

    setState(() {
      _isAnalyzing = true;
      _selectedDate = null;
      _selectedTime = null;
    });

    try {
      final result = await _doctorService.smartMatch(text);
      if (mounted) {
        setState(() {
          _matchResult = result;
          _selectedDate = result['recommended_date'];
          _selectedTime = result['recommended_time'];
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

  Future<void> _confirmAppointment() async {
    if (_matchResult == null || _selectedDate == null || _selectedTime == null) return;

    setState(() => _isBooking = true);
    try {
      final doctorId = _matchResult!['recommended_doctor']['id'];
      final type = _matchResult!['recommended_type'] ?? 'VIDEO';
      final symptoms = _matchResult!['symptoms_analyzed'] ?? _symptomsController.text.trim();

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
          // Re-fetch match to get updated non-conflicting slots
          try {
            final refreshed = await _doctorService.smartMatch(symptoms);
            if (mounted) {
              setState(() {
                _matchResult = refreshed;
                _selectedDate = refreshed['recommended_date'];
                _selectedTime = refreshed['recommended_time'];
              });
            }
          } catch (_) {}
        } else {
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
        child: _matchResult == null ? _buildInputScreen() : _buildConfirmationScreen(),
      ),
    );
  }

  Widget _buildInputScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What is happening to you?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us your symptoms or describe what you are feeling.',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _symptomsController,
            maxLines: 4,
            style: const TextStyle(fontSize: 16, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: 'Example: I have fever and cough since yesterday',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _toggleListening,
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? Colors.white : AppColors.primary,
                size: 20,
              ),
              label: Text(
                _isListening ? 'Listening...' : 'Speak your problem',
                style: TextStyle(
                  color: _isListening ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isListening ? Colors.red : AppColors.lightBlue,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Common Symptoms',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _commonSymptoms.map((symptom) {
              return ActionChip(
                label: Text(symptom),
                backgroundColor: Colors.white,
                labelStyle: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w500),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                onPressed: () => _addSymptom(symptom),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isAnalyzing ? null : _submitSymptoms,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
              child: _isAnalyzing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('Understanding your symptoms...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    )
                  : const Text('Find the right care', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationScreen() {
    final docData = _matchResult!['recommended_doctor'] ?? {};
    final doctorName = docData['name'] ?? 'Doctor';
    final hospitalName = docData['hospital_name'] ?? 'Kopargaon Rural Hospital';
    final specialization = _matchResult!['recommended_specialization'] ?? 'General Physician';
    final type = _matchResult!['recommended_type'] ?? 'VIDEO';
    final urgency = _matchResult!['urgency'] ?? 'MODERATE';

    final List<String> altDates = List<String>.from(_matchResult!['alternative_dates'] ?? []);
    final List<String> altTimes = List<String>.from(_matchResult!['alternative_times'] ?? []);
    final recommendedDate = _matchResult!['recommended_date'];
    final recommendedTime = _matchResult!['recommended_time'];

    Widget urgencyBanner = const SizedBox.shrink();
    if (urgency == 'EMERGENCY' || urgency == 'HIGH') {
      urgencyBanner = Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                urgency == 'EMERGENCY'
                    ? 'Urgent care needed. An immediate priority slot has been assigned.'
                    : 'Priority care recommended for your condition.',
                style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Appointment',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Recommended for your symptoms',
            style: TextStyle(fontSize: 15, color: Colors.green, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          urgencyBanner,

          // Recommended Doctor Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
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
                      Text(specialization, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(hospitalName, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        type == 'VIDEO' ? Icons.videocam : (type == 'AUDIO' ? Icons.phone : Icons.local_hospital),
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        type == 'VIDEO' ? 'Video' : (type == 'AUDIO' ? 'Audio' : 'In-Person'),
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Date Selection
          const Text('Recommended Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
          const SizedBox(height: 10),
          _buildSelectionChip(
            label: _formatDate(recommendedDate),
            isSelected: _selectedDate == recommendedDate,
            isRecommended: true,
            onTap: () => setState(() => _selectedDate = recommendedDate),
          ),
          if (altDates.length > 1) ...[
            const SizedBox(height: 16),
            const Text('Other Available Dates', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF475569))),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: altDates.where((d) => d != recommendedDate).map((d) {
                return _buildSelectionChip(
                  label: _formatDate(d),
                  isSelected: _selectedDate == d,
                  isRecommended: false,
                  onTap: () => setState(() => _selectedDate = d),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24),

          // Time Selection
          const Text('Recommended Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
          const SizedBox(height: 10),
          _buildSelectionChip(
            label: _formatTime(recommendedTime),
            isSelected: _selectedTime == recommendedTime,
            isRecommended: true,
            onTap: () => setState(() => _selectedTime = recommendedTime),
          ),
          if (altTimes.length > 1) ...[
            const SizedBox(height: 16),
            const Text('Other Available Times', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF475569))),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: altTimes.where((t) => t != recommendedTime).map((t) {
                return _buildSelectionChip(
                  label: _formatTime(t),
                  isSelected: _selectedTime == t,
                  isRecommended: false,
                  onTap: () => setState(() => _selectedTime = t),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: (_isBooking || _selectedDate == null || _selectedTime == null) ? null : _confirmAppointment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
              child: _isBooking
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('Booking appointment...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    )
                  : const Text('Confirm Appointment', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: _isBooking ? null : () => setState(() => _matchResult = null),
              child: const Text('Go Back', style: TextStyle(fontSize: 15, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionChip({
    required String label,
    required bool isSelected,
    required bool isRecommended,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRecommended) ...[
              Icon(
                isSelected ? Icons.check_circle : Icons.star,
                color: isSelected ? Colors.white : Colors.amber.shade700,
                size: 18,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1E293B),
                fontWeight: isSelected || isRecommended ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
