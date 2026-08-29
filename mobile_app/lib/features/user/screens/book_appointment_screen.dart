import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../services/doctor_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _symptomsController = TextEditingController();
  final DoctorService _doctorService = DoctorService();

  bool _isAnalyzing = false;
  bool _isBooking = false;
  Map<String, dynamic>? _matchResult;
  
  String? _selectedDate;
  String? _selectedTime;

  final List<String> _commonSymptoms = [
    'Fever', 'Cough', 'Pain', 'Weakness',
    'Breathing Problem', 'Stomach Problem', 'Headache', 'Skin Problem'
  ];

  void _addSymptom(String symptom) {
    final currentText = _symptomsController.text;
    if (currentText.isEmpty) {
      _symptomsController.text = symptom;
    } else {
      _symptomsController.text = '$currentText, $symptom';
    }
  }

  void _simulateVoiceInput() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Listening... Please speak your symptoms.')),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _symptomsController.text = 'I have a high fever and a bad cough since yesterday.';
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    });
  }

  void _showError(String rawError) {
    String message = 'Something went wrong on the server. Please try again.';
    final lowerError = rawError.toLowerCase();
    
    if (lowerError.contains('socketexception') || lowerError.contains('timeout') || lowerError.contains('network') || lowerError.contains('failed host lookup')) {
      message = 'Unable to connect.\nPlease check your internet connection and try again.';
    } else if (lowerError.contains('unauthorized') || lowerError.contains('token')) {
      message = 'Your session has expired.\nPlease log in again.';
    } else if (lowerError.contains('valid patient') || lowerError.contains('valid doctor') || lowerError.contains('invalid request')) {
      message = 'We could not book this appointment.\nPlease check the selected details.';
    } else if (lowerError.contains('slot') || lowerError.contains('conflict') || lowerError.contains('available')) {
      message = 'This appointment slot is no longer available.\nPlease choose another slot.';
    } else if (rawError.replaceAll('Exception: ', '').trim().isNotEmpty && !lowerError.contains('server error')) {
      message = rawError.replaceAll('Exception: ', '');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submitSymptoms() async {
    if (_symptomsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe what is happening to you.')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _selectedDate = null;
      _selectedTime = null;
    });
    
    try {
      final result = await _doctorService.smartMatch(_symptomsController.text.trim());
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
      final type = _matchResult!['recommended_type'];
      final symptoms = _matchResult!['symptoms_analyzed'];

      final response = await _doctorService.bookAppointment(
        doctorId: doctorId,
        date: _selectedDate!,
        time: _selectedTime!,
        type: type,
        notes: symptoms,
      );

      if (mounted) {
        setState(() => _isBooking = false);
        if (response.containsKey('error') || response.isEmpty) {
          _showError(response['error']?.toString() ?? 'Invalid request');
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Book Appointment', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 18)),
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
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us your symptoms or describe what you are feeling.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _symptomsController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Example: I have fever and cough since yesterday',
              hintStyle: TextStyle(color: Colors.grey.shade400),
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
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _simulateVoiceInput,
              icon: const Icon(Icons.mic, color: AppColors.primary),
              label: const Text('Speak your problem', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.lightBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _commonSymptoms.map((symptom) {
              return ActionChip(
                label: Text(symptom),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                onPressed: () => _addSymptom(symptom),
              );
            }).toList(),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isAnalyzing ? null : _submitSymptoms,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isAnalyzing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('Understanding your symptoms...', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    )
                  : const Text('Find the right care', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationScreen() {
    final doctorName = _matchResult!['recommended_doctor']['name'];
    final specialization = _matchResult!['recommended_specialization'];
    final type = _matchResult!['recommended_type'];
    final urgency = _matchResult!['urgency'];
    
    final List<String> altDates = List<String>.from(_matchResult!['alternative_dates'] ?? []);
    final List<String> altTimes = List<String>.from(_matchResult!['alternative_times'] ?? []);
    final recommendedDate = _matchResult!['recommended_date'];
    final recommendedTime = _matchResult!['recommended_time'];

    Widget urgencyBanner = const SizedBox.shrink();
    if (urgency == 'EMERGENCY') {
      urgencyBanner = Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 24),
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
                'Urgent medical attention recommended based on your symptoms.',
                style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
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
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Recommended for your symptoms',
            style: TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          urgencyBanner,
          
          // Doctor Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.lightBlue,
                  radius: 24,
                  child: const Icon(Icons.person, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doctorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(specialization, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    ],
                  ),
                ),
                Icon(
                  type == 'VIDEO' ? Icons.videocam : (type == 'AUDIO' ? Icons.phone : Icons.home_work),
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Date Selection
          const Text('Recommended Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildSelectionChip(
            label: _formatDate(recommendedDate),
            isSelected: _selectedDate == recommendedDate,
            isRecommended: true,
            onTap: () => setState(() => _selectedDate = recommendedDate),
          ),
          if (altDates.length > 1) ...[
            const SizedBox(height: 16),
            const Text('Other Available Dates', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
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
          const Text('Recommended Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildSelectionChip(
            label: _formatTime(recommendedTime),
            isSelected: _selectedTime == recommendedTime,
            isRecommended: true,
            onTap: () => setState(() => _selectedTime = recommendedTime),
          ),
          if (altTimes.length > 1) ...[
            const SizedBox(height: 16),
            const Text('Other Available Times', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
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

          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: (_isBooking || _selectedDate == null || _selectedTime == null) ? null : _confirmAppointment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isBooking
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('Booking appointment...', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    )
                  : const Text('Confirm Appointment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: TextButton(
              onPressed: _isBooking ? null : () => setState(() => _matchResult = null),
              child: const Text('Go Back', style: TextStyle(fontSize: 16, color: Colors.grey)),
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
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRecommended) ...[
              Icon(
                isSelected ? Icons.check_circle : Icons.star,
                color: isSelected ? Colors.white : Colors.amber,
                size: 18,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Color(0xFF1E293B),
                fontWeight: isSelected || isRecommended ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
