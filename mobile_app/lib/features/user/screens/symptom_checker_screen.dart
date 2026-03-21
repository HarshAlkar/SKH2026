import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../../providers/alert_provider.dart';
import '../../../providers/symptom_provider.dart';
import '../../../models/alert_model.dart';
import '../widgets/user_sidebar.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;



class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final List<String> _allSymptoms = [
    'Fever',
    'Cough',
    'Headache',
    'Vomiting',
    'Chest Pain',
    'Fatigue',
  ];

  final List<String> _selectedSymptoms = [];
  bool _isAnalyzing = false;
  bool _showResult = false;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _voiceText = '';
  String _sttError = '';
  String _selectedLanguage = 'English';
  String _localeId = 'en-IN';
  List<stt.LocaleName> _availableLocales = [];

  final Map<String, Map<String, dynamic>> _translations = {
    'English': {
      'title': 'AI Symptom Checker',
      'subtitle': 'How do you feel?',
      'desc': 'Our AI helps identify potential health concerns',
      'common': 'COMMON SYMPTOMS',
      'voice_desc': 'Or describe symptoms by voice',
      'tap_voice': 'Tap for Voice Input',
      'listening': 'Listening... Please speak now',
      'analyze': 'Analyze Symptoms',
      'analyzing': 'Analyzing...',
      'result_title': 'ANALYSIS RESULT',
      'consult': 'Consult Doctor',
      'notify': 'Notify ASHA',
      'error_init': 'Speech recognition not available',
      'symptoms': {
        'Fever': 'Fever',
        'Cough': 'Cough',
        'Headache': 'Headache',
        'Vomiting': 'Vomiting',
        'Chest Pain': 'Chest Pain',
        'Fatigue': 'Fatigue',
      }
    },
    'Hindi': {
      'title': 'AI लक्षण जाँचकर्ता',
      'subtitle': 'आप कैसा महसूस कर रहे हैं?',
      'desc': 'हमारा AI स्वास्थ्य संबंधी चिंताओं को पहचानने में मदद करता है',
      'common': 'सामान्य लक्षण',
      'voice_desc': 'या आवाज द्वारा लक्षणों का वर्णन करें',
      'tap_voice': 'वॉयस इनपुट के लिए टैप करें',
      'listening': 'सुन रहा हूँ... कृपया अभी बोलें',
      'analyze': 'लक्षणों का विश्लेषण करें',
      'analyzing': 'विश्लेषण कर रहा है...',
      'result_title': 'विश्लेषण परिणाम',
      'consult': 'डॉक्टर से सलाह लें',
      'notify': 'ASHA को सूचित करें',
      'error_init': 'वाक् पहचान उपलब्ध नहीं है',
      'symptoms': {
        'Fever': 'बुखार',
        'Cough': 'खांसी',
        'Headache': 'सिरदर्द',
        'Vomiting': 'उल्टी',
        'Chest Pain': 'सीने में दर्द',
        'Fatigue': 'थकान',
      }
    },
  };

  String _getTxt(String key) => _translations[_selectedLanguage]?[key] ?? key;
  String _getSymptomTxt(String symptom) => 
      (_translations[_selectedLanguage]?['symptoms'] as Map? ?? {})[symptom] ?? symptom;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      bool hasSpeech = await _speech.initialize(
        onError: (errorNotification) {
          debugPrint('STT Error: $errorNotification');
          if (mounted) {
            setState(() {
              _sttError = errorNotification.errorMsg;
              _isListening = false;
            });
          }
        },
        onStatus: (status) {
          debugPrint('STT Status: $status');
          if (status == 'notListening' || status == 'done') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
      
      if (hasSpeech) {
        _availableLocales = await _speech.locales();
        for (var locale in _availableLocales) {
          debugPrint('Available Locale: ${locale.name} [${locale.localeId}]');
        }
      }

      if (mounted) setState(() {});
      if (!hasSpeech) {
        debugPrint('The user has denied the use of speech recognition.');
      }
    } catch (e) {
      debugPrint('Speech init failed: $e');
    }
  }

  void _toggleListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _voiceText = '';
          _sttError = '';
        });
        _speech.listen(
          onResult: (val) => setState(() {
            _voiceText = val.recognizedWords;
            // Provide visual feedback if we got final results
            if (val.finalResult) {
              _isListening = false;
            }
          }),
          localeId: _localeId,
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 10),
          partialResults: true,
          onDevice: true,
          cancelOnError: true,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available or permission denied')),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _toggleSymptom(String symptom) {
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        _selectedSymptoms.remove(symptom);
      } else {
        _selectedSymptoms.add(symptom);
      }
    });
  }

  Future<void> _analyzeSymptoms() async {
    if (_selectedSymptoms.isEmpty && _voiceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select symptoms or use voice input')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _showResult = false;
    });

    try {
      final symptomProvider = Provider.of<SymptomProvider>(context, listen: false);
      
      final String input = _selectedSymptoms.join(', ') + 
                          (_voiceText.isNotEmpty ? ', $_voiceText' : '');
      
      await symptomProvider.analyzeSymptoms(
        symptomsText: input,
        recognizedText: _voiceText,
      );

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _showResult = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const UserSidebar(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.primary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),

        title: Column(
          children: [
            Text(
              _getTxt('title'),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'VitalReach',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: AppColors.primary),
            onSelected: (String lang) {
              setState(() {
                _selectedLanguage = lang;
                if (lang == 'Hindi') {
                  // Try to find a precise Hindi locale if available
                  var hiLocale = _availableLocales.firstWhere(
                    (l) => l.localeId.contains('hi'),
                    orElse: () => stt.LocaleName('hi-IN', 'Hindi'),
                  );
                  _localeId = hiLocale.localeId;
                } else {
                  var enLocale = _availableLocales.firstWhere(
                    (l) => l.localeId.contains('en'),
                    orElse: () => stt.LocaleName('en-IN', 'English'),
                  );
                  _localeId = enLocale.localeId;
                }
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(value: 'English', child: Text('English')),
              const PopupMenuItem(value: 'Hindi', child: Text('हिंदी (Hindi)')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getTxt('subtitle'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getTxt('desc'),
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 32),
              Text(
                _getTxt('common'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _allSymptoms.map((symptom) {
                  final isSelected = _selectedSymptoms.contains(symptom);
                  return FilterChip(
                    label: Text(_getSymptomTxt(symptom)),
                    selected: isSelected,
                    onSelected: (_) => _toggleSymptom(symptom),
                    selectedColor: AppColors.primary,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : const Color(0xFF2A7DE1).withOpacity(0.5),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),

                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              _buildVoiceInputSection(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isAnalyzing ? null : _analyzeSymptoms,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isAnalyzing
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.analytics_outlined),
                            const SizedBox(width: 12),
                            Text(
                              _getTxt('analyze'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              if (_showResult) ...[
                const SizedBox(height: 32),
                _buildResultCard(),
                const SizedBox(height: 24),
                _buildSeverityIndicators(),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.consultDoctor),
                        icon: const Icon(Icons.video_call_outlined),
                        label: Text(_getTxt('consult')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final alertProvider = Provider.of<AlertProvider>(context, listen: false);
                          alertProvider.addAlert(
                            AlertModel(
                              id: DateTime.now().toString(),
                              title: 'Symptom Alert: Viral Fever',
                              message: 'Patient Ramesh reported symptoms and AI suggested Viral Fever (Moderate).',
                              severity: 'Warning',
                              timestamp: DateTime.now(),
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Alert sent to ASHA worker'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },

                        icon: const Icon(Icons.notification_important_outlined),
                        label: Text(_getTxt('notify')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceInputSection() {
    return CustomPaint(
      painter: DashRectPainter(color: AppColors.primary.withOpacity(0.3)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F1FF).withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(24),

        child: Column(
          children: [
            Text(
              _getTxt('voice_desc'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: IconButton(
                iconSize: 40,
                onPressed: _toggleListening,
                icon: Icon(
                  _isListening ? Icons.stop : Icons.mic,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_voiceText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Recognized: $_voiceText',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: AppColors.primary,
                  ),
                ),
              ),
            if (_isListening)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Listening... Please speak now',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              )
            else if (_sttError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Error: $_sttError. Try again.',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _getTxt('tap_voice'),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final analysis = Provider.of<SymptomProvider>(context).lastAnalysis;
    if (analysis == null) return const SizedBox.shrink();

    final String disease = analysis['disease'] ?? 'Unknown';
    final String severity = analysis['severity'] ?? 'Moderate';
    final bool alertSent = analysis['alert_sent'] ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getTxt('result_title'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 1.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: severity == 'High' || severity == 'Critical' 
                      ? const Color(0xFFFFEEEE) 
                      : const Color(0xFFFFF7EF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 4, 
                      backgroundColor: severity == 'High' || severity == 'Critical' 
                          ? Colors.red 
                          : Colors.orange
                    ),
                    const SizedBox(width: 8),
                    Text(
                      severity.toUpperCase(),
                      style: TextStyle(
                        color: severity == 'High' || severity == 'Critical' 
                            ? Colors.red 
                            : Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            disease,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  alertSent 
                      ? 'Potentially serious condition detected. ASHA worker and doctor have been notified.'
                      : 'Maintain hydration and rest. Monitor symptoms carefully.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityIndicators() {
    final analysis = Provider.of<SymptomProvider>(context).lastAnalysis;
    final String currentSeverity = analysis != null ? analysis['severity'] ?? 'Moderate' : 'Moderate';
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatusChip('Low', Colors.green, currentSeverity == 'Low'),
        _buildStatusChip('Moderate', Colors.orange, currentSeverity == 'Moderate'),
        _buildStatusChip('High', Colors.red, currentSeverity == 'High' || currentSeverity == 'Critical'),
      ],
    );
  }

  Widget _buildStatusChip(String label, Color color, bool isCurrent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: isCurrent ? Border.all(color: color.withOpacity(0.3), width: 1.5) : null,
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 3, backgroundColor: color),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class DashRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashRectPainter({
    this.color = Colors.black,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint dashedPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    double x = size.width;
    double y = size.height;

    Path topPath = getDashedPath(const Offset(0, 0), Offset(x, 0), gap);
    Path rightPath = getDashedPath(Offset(x, 0), Offset(x, y), gap);
    Path bottomPath = getDashedPath(Offset(x, y), Offset(0, y), gap);
    Path leftPath = getDashedPath(Offset(0, y), const Offset(0, 0), gap);

    canvas.drawPath(topPath, dashedPaint);
    canvas.drawPath(rightPath, dashedPaint);
    canvas.drawPath(bottomPath, dashedPaint);
    canvas.drawPath(leftPath, dashedPaint);
  }

  Path getDashedPath(Offset start, Offset end, double gap) {
    Path path = Path();
    double distance = (end - start).distance;
    double dashWidth = gap;
    double dashSpace = gap;
    double currentDistance = 0;

    while (currentDistance < distance) {
      path.moveTo(
        start.dx + (end.dx - start.dx) * currentDistance / distance,
        start.dy + (end.dy - start.dy) * currentDistance / distance,
      );
      currentDistance += dashWidth;
      if (currentDistance > distance) currentDistance = distance;
      path.lineTo(
        start.dx + (end.dx - start.dx) * currentDistance / distance,
        start.dy + (end.dy - start.dy) * currentDistance / distance,
      );
      currentDistance += dashSpace;
    }
    return path;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
