import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/permission_dialog_service.dart';
import '../../../core/services/settings_store.dart';
import '../../../routes/app_routes.dart';
import '../../../providers/symptom_provider.dart';
import '../../ai_symptom_checker/services/symptom_dataset_service.dart';
import '../widgets/user_sidebar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;



class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  List<SymptomOption> _symptomOptions = [];
  List<SymptomOption> _skinSymptomOptions = [];
  bool _datasetLoading = true;

  final List<String> _selectedSymptoms = [];
  final List<String> _selectedSkinSymptoms = [];
  bool _isAnalyzing = false;
  bool _showResult = false;
  bool _notifying = false;
  String _checkerMode = 'symptoms';
  File? _skinImage;
  final ImagePicker _picker = ImagePicker();

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
      'tab_symptoms': 'Symptoms',
      'tab_skin': 'Skin photo',
      'skin_desc': 'Take or choose a clear photo of the affected skin',
      'take_photo': 'Camera',
      'pick_gallery': 'Gallery',
      'analyze_skin': 'Analyze Skin Photo',
      'skin_symptoms': 'Or select skin symptoms from dataset',
      'skin_disclaimer':
          'Screening only, not a diagnosis. Photo analysis uses CNN when available; symptom chips use the disease dataset (e.g. fungal infection, acne, psoriasis).',
      'result_title': 'ANALYSIS RESULT',
      'consult': 'Consult Doctor',
      'notify': 'Notify ASHA',
      'notified': 'ASHA notified',
      'disclaimer': 'This is a screening suggestion, not a medical diagnosis.',
      'confidence': 'Confidence',
      'select_first': 'Please select symptoms or use voice input',
      'analysis_failed': 'Analysis failed',
      'speech_denied': 'Speech recognition not available or permission denied',
      'skin_first': 'Take a skin photo or select skin symptoms',
      'low': 'Low',
      'moderate': 'Moderate',
      'high': 'High',
      'error_init': 'Speech recognition not available',
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
      'tab_symptoms': 'लक्षण',
      'tab_skin': 'त्वचा फोटो',
      'skin_desc': 'प्रभावित त्वचा की साफ तस्वीर लें या चुनें',
      'take_photo': 'कैमरा',
      'pick_gallery': 'गैलरी',
      'analyze_skin': 'त्वचा फोटो का विश्लेषण करें',
      'skin_symptoms': 'या त्वचा के लक्षण चुनें',
      'skin_disclaimer':
          'यह केवल स्क्रीनिंग है, निदान नहीं। फोटो CNN से और लक्षण डेटासेट से विश्लेषित होते हैं (जैसे फंगल संक्रमण, मुँहासे)।',
      'result_title': 'विश्लेषण परिणाम',
      'consult': 'डॉक्टर से सलाह लें',
      'notify': 'ASHA को सूचित करें',
      'notified': 'ASHA को सूचित किया गया',
      'disclaimer': 'यह स्क्रीनिंग सुझाव है, चिकित्सा निदान नहीं।',
      'confidence': 'विश्वास',
      'select_first': 'कृपया लक्षण चुनें या आवाज़ का उपयोग करें',
      'analysis_failed': 'विश्लेषण असफल रहा',
      'speech_denied': 'वाक् पहचान उपलब्ध नहीं है या अनुमति नहीं मिली',
      'skin_first': 'त्वचा की तस्वीर लें या त्वचा के लक्षण चुनें',
      'low': 'कम',
      'moderate': 'मध्यम',
      'high': 'उच्च',
      'error_init': 'वाक् पहचान उपलब्ध नहीं है',
    },
  };

  String _getTxt(String key) => _translations[_selectedLanguage]?[key] ?? key;
  String _symptomLabel(SymptomOption option) =>
      option.labelFor(_selectedLanguage == 'Hindi' ? 'hi' : 'en');

  @override
  void initState() {
    super.initState();
    _applyStoredLanguage();
    _initSpeech();
    _loadDataset();
  }

  Future<void> _loadDataset() async {
    try {
      final common = await SymptomDatasetService.instance.commonSymptoms();
      final skin = await SymptomDatasetService.instance.skinSymptoms();
      if (!mounted) return;
      setState(() {
        _symptomOptions = common;
        _skinSymptomOptions = skin;
        _datasetLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _datasetLoading = false);
    }
  }

  void _applyStoredLanguage() {
    final hindi = SettingsStore.instance.isHindi;
    _selectedLanguage = hindi ? 'Hindi' : 'English';
    _localeId = hindi ? 'hi-IN' : 'en-IN';
  }

  Future<void> _setLanguage(String lang) async {
    setState(() {
      _selectedLanguage = lang;
      if (lang == 'Hindi') {
        final hiLocale = _availableLocales.where((l) => l.localeId.contains('hi'));
        _localeId = hiLocale.isNotEmpty ? hiLocale.first.localeId : 'hi-IN';
      } else {
        final enLocale = _availableLocales.where((l) => l.localeId.contains('en'));
        _localeId = enLocale.isNotEmpty ? enLocale.first.localeId : 'en-IN';
      }
    });
    await SettingsStore.instance.setLanguage(lang == 'Hindi' ? 'hi' : 'en');
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
        SnackBar(content: Text(_getTxt('speech_denied'))),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _toggleSymptom(String token) {
    setState(() {
      if (_selectedSymptoms.contains(token)) {
        _selectedSymptoms.remove(token);
      } else {
        _selectedSymptoms.add(token);
      }
    });
  }

  void _toggleSkinSymptom(String token) {
    setState(() {
      if (_selectedSkinSymptoms.contains(token)) {
        _selectedSkinSymptoms.remove(token);
      } else {
        _selectedSkinSymptoms.add(token);
      }
    });
  }

  String _selectedSymptomLabels(List<String> tokens) {
    final options = [..._symptomOptions, ..._skinSymptomOptions];
    return tokens.map((token) {
      final match = options.where((o) => o.token == token);
      if (match.isNotEmpty) return _symptomLabel(match.first);
      return token.replaceAll('_', ' ');
    }).join(', ');
  }

  Future<void> _analyzeSymptoms() async {
    if (_selectedSymptoms.isEmpty && _voiceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getTxt('select_first'))),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _showResult = false;
    });

    try {
      final symptomProvider = Provider.of<SymptomProvider>(context, listen: false);
      
      final String input = _selectedSymptomLabels(_selectedSymptoms) +
                          (_voiceText.isNotEmpty ? ', $_voiceText' : '');
      
      await symptomProvider.analyzeSymptoms(
        symptomsText: input,
        recognizedText: _voiceText,
        language: _selectedLanguage == 'Hindi' ? 'hi' : 'en',
        selectedTokens: List<String>.from(_selectedSymptoms),
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
          SnackBar(content: Text('${_getTxt('analysis_failed')}: $e')),
        );
      }
    }
  }

  Future<void> _pickSkinImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final allowed = await PermissionDialogService.ensure(
        context,
        permission: Permission.camera,
        title: _selectedLanguage == 'Hindi' ? 'कैमरा अनुमति' : 'Allow camera',
        message: _selectedLanguage == 'Hindi'
            ? 'त्वचा फोटो लेने के लिए कैमरा अनुमति दें।'
            : 'Allow camera so VitalReach can take a skin photo.',
      );
      if (!allowed || !mounted) return;
    }
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() {
        _skinImage = File(picked.path);
        _showResult = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_getTxt('analysis_failed')}: $e')),
      );
    }
  }

  Future<void> _analyzeSkin() async {
    if (_skinImage == null && _selectedSkinSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getTxt('skin_first'))),
      );
      return;
    }
    setState(() {
      _isAnalyzing = true;
      _showResult = false;
    });
    try {
      await Provider.of<SymptomProvider>(context, listen: false).analyzeSkin(
        _skinImage,
        language: _selectedLanguage == 'Hindi' ? 'hi' : 'en',
        skinSymptomTokens: List<String>.from(_selectedSkinSymptoms),
      );
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _showResult = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_getTxt('analysis_failed')}: $e')),
      );
    }
  }

  Future<void> _notifyAsha() async {
    final analysis = Provider.of<SymptomProvider>(context, listen: false).lastAnalysis;
    if (analysis == null) return;
    setState(() => _notifying = true);
    try {
      await ApiService().post('/alerts/notifications/', body: {
        'disease': analysis['disease'] ?? 'Symptom alert',
        'severity': analysis['severity'] ?? 'Moderate',
      });
      if (!mounted) return;
      analysis['alert_sent'] = true;
      setState(() => _notifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getTxt('notified')),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _notifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not notify ASHA: $e')),
      );
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
              AppConstants.appName,
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
            onSelected: _setLanguage,
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

              const SizedBox(height: 24),
              _buildModeToggle(),
              const SizedBox(height: 24),
              if (_checkerMode == 'symptoms') ...[
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
              if (_datasetLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ))
              else if (_symptomOptions.isEmpty)
                Text(
                  _getTxt('select_first'),
                  style: const TextStyle(color: AppColors.textSecondary),
                )
              else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _symptomOptions.map((option) {
                  final isSelected = _selectedSymptoms.contains(option.token);
                  return FilterChip(
                    label: Text(_symptomLabel(option)),
                    selected: isSelected,
                    onSelected: (_) => _toggleSymptom(option.token),
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
              ] else ...[
                _buildSkinSection(),
              ],
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
                          final already = Provider.of<SymptomProvider>(context, listen: false)
                                  .lastAnalysis?['alert_sent'] ==
                              true;
                          if (already || _notifying) return;
                          _notifyAsha();
                        },
                        icon: const Icon(Icons.notification_important_outlined),
                        label: Text(
                          Provider.of<SymptomProvider>(context).lastAnalysis?['alert_sent'] == true
                              ? _getTxt('notified')
                              : _getTxt('notify'),
                        ),
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

  Widget _buildModeToggle() {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
        ButtonSegment(
          value: 'symptoms',
          label: Text(_getTxt('tab_symptoms')),
          icon: const Icon(Icons.sick_outlined),
        ),
        ButtonSegment(
          value: 'skin',
          label: Text(_getTxt('tab_skin')),
          icon: const Icon(Icons.photo_camera_outlined),
        ),
      ],
      selected: {_checkerMode},
      onSelectionChanged: (value) {
        setState(() {
          _checkerMode = value.first;
          _showResult = false;
        });
      },
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return AppColors.primary;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.white;
        }),
      ),
      ),
    );
  }

  Widget _buildSkinSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getTxt('skin_desc'),
          style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          clipBehavior: Clip.antiAlias,
          child: _skinImage == null
              ? const Center(
                  child: Icon(Icons.image_outlined, size: 56, color: Colors.grey),
                )
              : Image.file(_skinImage!, fit: BoxFit.cover),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickSkinImage(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(_getTxt('take_photo')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickSkinImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(_getTxt('pick_gallery')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _getTxt('skin_symptoms'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _skinSymptomOptions.map((option) {
            final isSelected = _selectedSkinSymptoms.contains(option.token);
            return FilterChip(
              label: Text(_symptomLabel(option)),
              selected: isSelected,
              onSelected: (_) => _toggleSkinSymptom(option.token),
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected ? AppColors.primary : const Color(0xFF2A7DE1).withOpacity(0.5),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text(
          _getTxt('skin_disclaimer'),
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isAnalyzing ? null : _analyzeSkin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isAnalyzing
                ? const SizedBox(
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
                        _getTxt('analyze_skin'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
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

    final String disease = analysis['disease_display']?.toString() ??
        analysis['disease']?.toString() ??
        'Unknown';
    final String severity = analysis['severity_display']?.toString() ??
        analysis['severity']?.toString() ??
        'Moderate';
    final bool alertSent = analysis['alert_sent'] ?? false;
    final num confidence = analysis['confidence'] is num
        ? analysis['confidence'] as num
        : 0;
    final List top = analysis['top_predictions'] is List
        ? analysis['top_predictions'] as List
        : const [];
    final advice = analysis['advice']?.toString() ??
        (alertSent
            ? (_selectedLanguage == 'Hindi'
                ? 'संभावित गंभीर स्थिति। आशा कार्यकर्ता और डॉक्टर को सूचित किया गया है।'
                : 'Potentially serious condition detected. ASHA worker and doctor have been notified.')
            : (_selectedLanguage == 'Hindi'
                ? 'पर्याप्त पानी पिएँ और आराम करें। लक्षणों पर नज़र रखें।'
                : 'Maintain hydration and rest. Monitor symptoms carefully.'));

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
          const SizedBox(height: 8),
          Text(
            '${_getTxt('confidence')} ${(confidence * 100).clamp(0, 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (top.length > 1) ...[
            const SizedBox(height: 12),
            ...top.take(3).map((row) {
              final map = row is Map ? Map<String, dynamic>.from(row) : <String, dynamic>{};
              final name = map['disease_display']?.toString() ?? map['disease']?.toString() ?? '';
              final score = map['confidence'] is num ? map['confidence'] as num : 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(child: Text(name, style: const TextStyle(fontSize: 13))),
                    Text(
                      '${(score * 100).clamp(0, 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  advice,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            analysis['disclaimer']?.toString() ?? _getTxt('disclaimer'),
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
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
        _buildStatusChip(_getTxt('low'), Colors.green, currentSeverity == 'Low'),
        _buildStatusChip(_getTxt('moderate'), Colors.orange, currentSeverity == 'Moderate'),
        _buildStatusChip(_getTxt('high'), Colors.red, currentSeverity == 'High' || currentSeverity == 'Critical'),
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
