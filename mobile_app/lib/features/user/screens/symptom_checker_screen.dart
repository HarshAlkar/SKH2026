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
import '../../ai_health_chat/models/screening_chat_context.dart';
import '../../ai_health_chat/screens/shared_ai_health_chat_screen.dart';
import '../../ai_symptom_checker/services/symptom_dataset_service.dart';
import '../../ai_symptom_checker/services/symptom_ml_service.dart';
import '../../ai_symptom_checker/services/symptom_text_extractor.dart';
import '../../one_health/escalation_policy.dart';
import '../../one_health/escalation_sheet.dart';
import '../../one_health/screening_health_steps.dart';
import '../../one_health/widgets/screening_result_view.dart';
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
  final List<String> _extractedSymptoms = [];
  final TextEditingController _freeTextCtrl = TextEditingController();
  bool _isAnalyzing = false;
  bool _showResult = false;
  bool _notifying = false;
  String _checkerMode = 'symptoms';
  File? _skinImage;
  bool _skinImageConfirmed = false;
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
      'take_photo': 'Take Photo',
      'pick_gallery': 'Choose from Gallery',
      'analyze_skin': 'Analyze Skin',
      'retake': 'Retake',
      'use_photo': 'Use Photo',
      'camera_denied':
          'Camera permission was denied. You can still choose a photo from Gallery.',
      'skin_symptoms': 'Or select skin symptoms from dataset',
      'skin_disclaimer':
          'AI-assisted skin screening only. Screening confidence is not a confirmed diagnosis. Professional evaluation recommended.',
      'result_title': 'AI SKIN SCREENING',
      'ask_ai': 'Ask AI about this',
      'consult': 'Contact Doctor',
      'notify': 'Contact ASHA',
      'notified': 'ASHA notified',
      'disclaimer':
          'AI-assisted screening only. This is not a medical or veterinary diagnosis.',
      'possible_condition': 'Possible condition (screening)',
      'confidence': 'AI confidence',
      'select_first':
          'Please select at least one symptom or describe what you are experiencing.',
      'describe_title': 'Describe your symptoms',
      'describe_hint':
          'Example: Fever for 3 days, headache and vomiting',
      'detected': 'Symptoms detected',
      'voice_note':
          'Voice transcription may require connectivity. Typed text works offline.',
      'insufficient':
          "We couldn't confidently identify enough symptoms from your description.",
      'insufficient_hint':
          'Please add more details or select symptoms from the list.',
      'ai_source': 'AI source',
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
      'take_photo': 'फोटो लें',
      'pick_gallery': 'गैलरी से चुनें',
      'analyze_skin': 'त्वचा का विश्लेषण करें',
      'retake': 'फिर से लें',
      'use_photo': 'फोटो उपयोग करें',
      'camera_denied':
          'कैमरा अनुमति नहीं मिली। आप गैलरी से फोटो चुन सकते हैं।',
      'skin_symptoms': 'या त्वचा के लक्षण चुनें',
      'skin_disclaimer':
          'यह केवल स्क्रीनिंग है, निदान नहीं। फोटो CNN से और लक्षण डेटासेट से विश्लेषित होते हैं (जैसे फंगल संक्रमण, मुँहासे)।',
      'result_title': 'AI त्वचा स्क्रीनिंग',
      'ask_ai': 'इसके बारे में AI से पूछें',
      'consult': 'डॉक्टर से संपर्क',
      'notify': 'ASHA से संपर्क',
      'notified': 'ASHA को सूचित किया गया',
      'disclaimer':
          'स्क्रीनिंग से जोखिम का संकेत — योग्य स्वास्थ्य पेशेवर से सलाह लें। यह चिकित्सा निदान नहीं है।',
      'possible_condition': 'संभावित स्थिति (स्क्रीनिंग)',
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
    'Marathi': {
      'title': 'AI लक्षण तपासणी',
      'subtitle': 'तुम्हाला कसे वाटते?',
      'desc': 'आमचे AI आरोग्य चिंता ओळखण्यात मदत करते',
      'common': 'सामान्य लक्षणे',
      'voice_desc': 'किंवा आवाजाने लक्षणे सांगा',
      'tap_voice': 'व्हॉइस इनपुटसाठी टॅप करा',
      'listening': 'ऐकत आहे... कृपया बोला',
      'analyze': 'लक्षणे तपासा',
      'analyzing': 'तपासत आहे...',
      'tab_symptoms': 'लक्षणे',
      'tab_skin': 'त्वचा फोटो',
      'skin_desc': 'प्रभावित त्वचेचा स्पष्ट फोटो घ्या',
      'take_photo': 'फोटो घ्या',
      'pick_gallery': 'गॅलरीतून निवडा',
      'analyze_skin': 'त्वचा तपासा',
      'retake': 'पुन्हा घ्या',
      'use_photo': 'फोटो वापरा',
      'camera_denied':
          'कॅमेरा परवानगी नाही. तुम्ही गॅलरीतून फोटो निवडू शकता.',
      'skin_symptoms': 'किंवा त्वचा लक्षणे निवडा',
      'skin_disclaimer': 'फक्त स्क्रीनिंग — निदान नाही.',
      'result_title': 'AI त्वचा स्क्रीनिंग',
      'ask_ai': 'याबद्दल AI ला विचारा',
      'consult': 'डॉक्टरांशी संपर्क',
      'notify': 'आशेशी संपर्क',
      'notified': 'आशाला कळवले',
      'disclaimer':
          'स्क्रीनिंगमुळे धोका दिसतो — पात्र आरोग्य तज्ज्ञांचा सल्ला घ्या. हे वैद्यकीय निदान नाही.',
      'possible_condition': 'संभाव्य स्थिती (स्क्रीनिंग)',
      'confidence': 'विश्वास',
      'select_first': 'कृपया लक्षणे निवडा किंवा आवाज वापरा',
      'analysis_failed': 'तपास अयशस्वी',
      'speech_denied': 'आवाज ओळख उपलब्ध नाही',
      'skin_first': 'त्वचा फोटो घ्या किंवा लक्षणे निवडा',
      'low': 'कमी',
      'moderate': 'मध्यम',
      'high': 'उच्च',
      'error_init': 'आवाज ओळख उपलब्ध नाही',
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
    _freeTextCtrl.addListener(() {
      if (_voiceText.isNotEmpty && _freeTextCtrl.text != _voiceText) {
        // user edited transcribed text — keep in sync for analyze
      }
    });
  }

  @override
  void dispose() {
    _freeTextCtrl.dispose();
    super.dispose();
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
    final marathi = SettingsStore.instance.isMarathi;
    _selectedLanguage = marathi ? 'Marathi' : (hindi ? 'Hindi' : 'English');
    _localeId = hindi || marathi ? 'hi-IN' : 'en-IN';
  }

  Future<void> _setLanguage(String lang) async {
    setState(() {
      _selectedLanguage = lang;
      if (lang == 'Hindi' || lang == 'Marathi') {
        final hiLocale = _availableLocales.where((l) => l.localeId.contains('hi'));
        _localeId = hiLocale.isNotEmpty ? hiLocale.first.localeId : 'hi-IN';
      } else {
        final enLocale = _availableLocales.where((l) => l.localeId.contains('en'));
        _localeId = enLocale.isNotEmpty ? enLocale.first.localeId : 'en-IN';
      }
    });
    final code = lang == 'Hindi' ? 'hi' : (lang == 'Marathi' ? 'mr' : 'en');
    await SettingsStore.instance.setLanguage(code);
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
            _freeTextCtrl.text = val.recognizedWords;
            _freeTextCtrl.selection = TextSelection.fromPosition(
              TextPosition(offset: _freeTextCtrl.text.length),
            );
            if (val.finalResult) {
              _isListening = false;
              _refreshExtractedFromText();
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

  void _refreshExtractedFromText() {
    final text = _freeTextCtrl.text.trim();
    if (text.isEmpty) {
      setState(() => _extractedSymptoms.clear());
      return;
    }
    final vocab = SymptomMlService.instance.featureVocabulary.toSet();
    final result = SymptomTextExtractor.instance.extract(
      text,
      vocabulary: vocab.isEmpty ? null : vocab,
    );
    setState(() {
      _extractedSymptoms
        ..clear()
        ..addAll(result.extracted);
    });
  }

  void _removeExtracted(String token) {
    setState(() => _extractedSymptoms.remove(token));
  }

  Future<void> _analyzeSymptoms() async {
    final freeText = _freeTextCtrl.text.trim();
    if (_selectedSymptoms.isEmpty && freeText.isEmpty && _voiceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getTxt('select_first'))),
      );
      return;
    }

    // Refresh extraction from current text before merging.
    if (freeText.isNotEmpty || _voiceText.isNotEmpty) {
      // Warm TFLite labels so vocabulary is available for filtering.
      await SymptomMlService.instance.tryPredict(const ['__warmup__']);
      final result = SymptomTextExtractor.instance.extract(
        freeText.isNotEmpty ? freeText : _voiceText,
        vocabulary: SymptomMlService.instance.featureVocabulary.isEmpty
            ? null
            : SymptomMlService.instance.featureVocabulary.toSet(),
      );
      setState(() {
        _extractedSymptoms
          ..clear()
          ..addAll(result.extracted);
      });

      if (_selectedSymptoms.isEmpty && result.extracted.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_getTxt('insufficient')} ${_getTxt('insufficient_hint')}',
            ),
          ),
        );
        return;
      }
    }

    setState(() {
      _isAnalyzing = true;
      _showResult = false;
    });

    try {
      final symptomProvider = Provider.of<SymptomProvider>(context, listen: false);
      final merged = <String>{
        ..._selectedSymptoms,
        ..._extractedSymptoms,
      }.toList();

      final String input = [
        _selectedSymptomLabels(_selectedSymptoms),
        if (freeText.isNotEmpty) freeText,
      ].where((s) => s.trim().isNotEmpty).join('. ');

      await symptomProvider.analyzeSymptoms(
        symptomsText: input,
        recognizedText: _voiceText,
        language: _selectedLanguage == 'Hindi'
            ? 'hi'
            : (_selectedLanguage == 'Marathi' ? 'mr' : 'en'),
        selectedTokens: merged,
      );

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _showResult = true;
        });
        final analysis = symptomProvider.lastAnalysis;
        if (analysis?['insufficient_symptoms'] == true) {
          return;
        }
        // Result-first: do not auto-open escalation sheet.
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
      if (!allowed || !mounted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getTxt('camera_denied')),
            action: SnackBarAction(
              label: _getTxt('pick_gallery'),
              onPressed: () => _pickSkinImage(ImageSource.gallery),
            ),
          ),
        );
        return;
      }
    } else {
      final allowed = await PermissionDialogService.ensure(
        context,
        permission: Permission.photos,
        title: _selectedLanguage == 'Hindi' ? 'गैलरी अनुमति' : 'Allow photos',
        message: _selectedLanguage == 'Hindi'
            ? 'त्वचा फोटो चुनने के लिए गैलरी अनुमति दें।'
            : 'Allow photo access so VitalReach can use a gallery image for skin screening.',
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
      final file = File(picked.path);
      if (!await file.exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read the selected image.')),
        );
        return;
      }
      setState(() {
        _skinImage = file;
        _skinImageConfirmed = false;
        _showResult = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image capture failed: $e'),
          action: source == ImageSource.camera
              ? SnackBarAction(
                  label: _getTxt('pick_gallery'),
                  onPressed: () => _pickSkinImage(ImageSource.gallery),
                )
              : null,
        ),
      );
    }
  }

  void _retakeSkinPhoto() {
    setState(() {
      _skinImage = null;
      _skinImageConfirmed = false;
      _showResult = false;
    });
  }

  void _confirmSkinPhoto() {
    if (_skinImage == null) return;
    setState(() => _skinImageConfirmed = true);
  }

  Future<void> _analyzeSkin() async {
    if (_skinImage == null && _selectedSkinSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getTxt('skin_first'))),
      );
      return;
    }
    if (_skinImage != null && !_skinImageConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getTxt('use_photo'))),
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
        language: _selectedLanguage == 'Hindi'
            ? 'hi'
            : (_selectedLanguage == 'Marathi' ? 'mr' : 'en'),
        skinSymptomTokens: List<String>.from(_selectedSkinSymptoms),
      );
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _showResult = true;
      });
      // Result-first: escalation only via explicit buttons.
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_getTxt('analysis_failed')}: $e')),
      );
    }
  }

  String _langCode() {
    if (_selectedLanguage == 'Hindi') return 'hi';
    if (_selectedLanguage == 'Marathi') return 'mr';
    return 'en';
  }

  ScreeningDomain _resultDomain() {
    return _checkerMode == 'skin' ? ScreeningDomain.skin : ScreeningDomain.human;
  }

  void _openAiChat() {
    final analysis = Provider.of<SymptomProvider>(context, listen: false).lastAnalysis;
    if (analysis == null) return;
    final finding = analysis['possible_condition']?.toString() ??
        analysis['disease']?.toString() ??
        'Elevated-risk screening result';
    final severity = analysis['severity']?.toString() ?? 'Moderate';
    final conf = analysis['confidence'] is num
        ? (analysis['confidence'] as num).toDouble()
        : null;
    final symptoms = _checkerMode == 'skin'
        ? List<String>.from(_selectedSkinSymptoms)
        : [
            ..._selectedSymptoms,
            ..._extractedSymptoms,
          ];
    final domain = _resultDomain();
    final steps = ScreeningHealthSteps.forResult(
      domain: domain,
      severity: severity,
      condition: finding,
      symptoms: symptoms,
    );
    SharedAIHealthChat.open(
      context,
      screeningContext: ScreeningChatContext(
        domain: domain,
        possibleFinding: finding,
        severity: severity,
        confidence: conf,
        advice: analysis['message']?.toString() ?? analysis['advice']?.toString(),
        explanation: ScreeningHealthSteps.explanation(
          domain: domain,
          severity: severity,
          possibleFinding: finding,
        ),
        nextSteps: steps,
        symptoms: symptoms,
        aiSource: analysis['source']?.toString(),
        rawResult: Map<String, dynamic>.from(analysis),
      ),
    );
  }

  void _escalateHuman({required bool preferDoctor}) {
    final analysis = Provider.of<SymptomProvider>(context, listen: false).lastAnalysis;
    final finding = analysis?['possible_condition']?.toString() ??
        analysis?['disease']?.toString() ??
        'Elevated-risk screening result';
    final severity = analysis?['severity']?.toString() ?? 'High';
    final symptoms = _checkerMode == 'skin'
        ? _selectedSkinSymptoms.join(', ')
        : [..._selectedSymptoms, ..._extractedSymptoms].join(', ');
    final summary = EscalationPolicy.careTeamSummary(
      domain: _resultDomain(),
      possibleFinding: finding,
      severity: severity,
      symptoms: symptoms,
      timestamp: DateTime.now(),
      offlineQueued: analysis?['queued_offline'] == true,
      aiSource: analysis?['source']?.toString(),
    );
    if (preferDoctor) {
      showEscalationSheet(
        context,
        severity: severity,
        isAnimal: false,
        language: _langCode(),
        summary: summary,
        forceShow: true,
      );
    } else {
      showEscalationSheet(
        context,
        severity: severity,
        isAnimal: false,
        language: _langCode(),
        summary: summary,
        forceShow: true,
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
              const PopupMenuItem(value: 'Marathi', child: Text('मराठी (Marathi)')),
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
              _buildDescribeSymptomsSection(),
              const SizedBox(height: 24),
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
          if (value.first != 'skin') {
            _skinImageConfirmed = false;
          }
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
        if (_skinImage == null) ...[
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
        ] else if (!_skinImageConfirmed) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _retakeSkinPhoto,
                  icon: const Icon(Icons.refresh),
                  label: Text(_getTxt('retake')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _confirmSkinPhoto,
                  icon: const Icon(Icons.check),
                  label: Text(_getTxt('use_photo')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Preview the photo, then tap Use Photo before analysis.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _retakeSkinPhoto,
                  icon: const Icon(Icons.refresh),
                  label: Text(_getTxt('retake')),
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
        ],
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
            onPressed: _isAnalyzing
                ? null
                : ((_skinImage != null && _skinImageConfirmed) ||
                        _selectedSkinSymptoms.isNotEmpty
                    ? _analyzeSkin
                    : null),
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

  Widget _buildDescribeSymptomsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getTxt('describe_title'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _freeTextCtrl,
          maxLength: 1000,
          maxLines: 4,
          minLines: 3,
          onChanged: (_) => _refreshExtractedFromText(),
          decoration: InputDecoration(
            hintText: _getTxt('describe_hint'),
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
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        Text(
          _getTxt('voice_note'),
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        if (_extractedSymptoms.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            _getTxt('detected'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _extractedSymptoms.map((token) {
              return InputChip(
                label: Text(token.replaceAll('_', ' ')),
                onDeleted: () => _removeExtracted(token),
                backgroundColor: const Color(0xFFE8F1FF),
                side: BorderSide(color: AppColors.primary.withOpacity(0.35)),
              );
            }).toList(),
          ),
        ],
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

    final String disease = analysis['possible_condition']?.toString() ??
        analysis['disease_display']?.toString() ??
        analysis['headline']?.toString() ??
        analysis['disease']?.toString() ??
        'Elevated-risk screening result';
    final String severity = analysis['severity_display']?.toString() ??
        analysis['severity']?.toString() ??
        'Moderate';
    final num confidence = analysis['confidence'] is num
        ? analysis['confidence'] as num
        : 0;
    final source = analysis['source']?.toString() ?? 'unknown';
    final scoreType = analysis['score_type']?.toString() ?? '';
    final isFallback =
        scoreType == 'symptom_match_fallback' || source.contains('dataset');
    final domain = _resultDomain();
    final symptoms = domain == ScreeningDomain.skin
        ? List<String>.from(_selectedSkinSymptoms)
        : [..._selectedSymptoms, ..._extractedSymptoms];
    final steps = ScreeningHealthSteps.forResult(
      domain: domain,
      severity: severity,
      condition: disease,
      symptoms: symptoms,
    );
    final band = EscalationPolicy.normalize(severity);
    final doctorFirst = EscalationPolicy.preferDoctorFirst(band);

    String sourceLabel;
    switch (source) {
      case 'skin_cnn_ondevice':
        sourceLabel = 'On-device ML';
        break;
      case 'symptom_mlp_ondevice':
        sourceLabel = 'On-device ML';
        break;
      case 'dataset_local':
      case 'dataset_skin':
        sourceLabel = 'Fallback';
        break;
      case 'server_ml':
      case 'symptom_ml':
        sourceLabel = 'Server ML';
        break;
      default:
        sourceLabel = source.contains('ondevice')
            ? 'On-device ML'
            : (source.contains('fallback') || source.contains('dataset')
                ? 'Fallback'
                : source);
    }

    final List top = analysis['top_predictions'] is List
        ? analysis['top_predictions'] as List
        : const [];
    final extra = <Widget>[];
    if (top.isNotEmpty) {
      extra.add(const SizedBox(height: 12));
      extra.add(
        Text(
          'Other possible findings to discuss',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      );
      extra.add(const SizedBox(height: 8));
      for (final row in top.take(3)) {
        final map = row is Map
            ? Map<String, dynamic>.from(row)
            : <String, dynamic>{};
        final name = map['disease']?.toString() ?? '';
        final score = map['confidence'] is num
            ? map['confidence'] as num
            : (map['probability'] is num ? map['probability'] as num : 0);
        final pct = isFallback
            ? '${(score * 100).clamp(0, 100).toStringAsFixed(0)}% (rank)'
            : '${(score * 100).clamp(0, 100).toStringAsFixed(1)}%';
        extra.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(child: Text(name, style: const TextStyle(fontSize: 13))),
                Text(pct, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        );
      }
    }

    return ScreeningResultView(
      domain: domain,
      title: domain == ScreeningDomain.skin
          ? _getTxt('result_title')
          : 'SCREENING RESULT',
      possibleFinding: disease,
      severity: severity,
      confidence: confidence > 0 ? confidence.toDouble() : null,
      confidenceIsFallback: isFallback,
      aiSourceLabel: '${_getTxt('ai_source')}: $sourceLabel',
      explanation: ScreeningHealthSteps.explanation(
        domain: domain,
        severity: severity,
        possibleFinding: disease,
      ),
      nextSteps: steps,
      whenToSeekHelp: EscalationPolicy.whenToSeekHelp(
        severity: severity,
        domain: domain,
      ),
      disclaimer: analysis['disclaimer']?.toString() ?? _getTxt('disclaimer'),
      queuedOffline: analysis['queued_offline'] == true,
      extraTop: extra,
      onAskAi: _openAiChat,
      onContactPrimary: EscalationPolicy.shouldShowEscalationButtons(band)
          ? () {
              if (doctorFirst) {
                _escalateHuman(preferDoctor: true);
              } else {
                final already = analysis['alert_sent'] == true;
                if (!already && !_notifying) {
                  _notifyAsha();
                }
                _escalateHuman(preferDoctor: false);
              }
            }
          : null,
      onContactSecondary: EscalationPolicy.shouldShowEscalationButtons(band)
          ? () {
              if (doctorFirst) {
                final already = analysis['alert_sent'] == true;
                if (!already && !_notifying) {
                  _notifyAsha();
                }
                Navigator.pushNamed(context, AppRoutes.ashaWorkers);
              } else {
                Navigator.pushNamed(context, AppRoutes.consultDoctor);
              }
            }
          : null,
      primaryContactLabel: doctorFirst ? _getTxt('consult') : _getTxt('notify'),
      secondaryContactLabel: doctorFirst ? _getTxt('notify') : _getTxt('consult'),
      primaryContactIcon: doctorFirst
          ? Icons.medical_services_outlined
          : Icons.health_and_safety_outlined,
      secondaryContactIcon: doctorFirst
          ? Icons.health_and_safety_outlined
          : Icons.medical_services_outlined,
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
