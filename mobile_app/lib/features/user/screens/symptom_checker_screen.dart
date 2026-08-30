import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/l10n/language_id_service.dart';
import '../../../core/services/locale_controller.dart';
import '../../../core/services/permission_dialog_service.dart';
import '../../../core/services/voice_recognition_service.dart';
import '../../../l10n/l10n.dart';
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
import '../../one_health/screening_result_view.dart';
import '../widgets/user_sidebar.dart';



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

  final VoiceRecognitionService _voice = VoiceRecognitionService.instance;
  bool _isListening = false;
  bool _voiceAnalyzeQueued = false;
  String _voiceText = '';
  String _sttError = '';
  String _selectedLanguage = 'English';
  String _localeId = 'en-IN';

  String _getTxt(String key) {
    final l = context.l10n;
    switch (key) {
      case 'title':
        return l.aiSymptomChecker;
      case 'subtitle':
        return l.symptomHowFeel;
      case 'desc':
        return l.symptomDesc;
      case 'common':
        return l.commonSymptoms;
      case 'voice_desc':
        return l.voiceDesc;
      case 'tap_voice':
        return l.tapVoice;
      case 'listening':
        return l.listeningSpeak;
      case 'analyze':
        return l.analyzeSymptoms;
      case 'analyzing':
        return l.analyzing;
      case 'tab_symptoms':
        return l.tabSymptoms;
      case 'tab_skin':
        return l.tabSkin;
      case 'skin_desc':
        return l.skinDesc;
      case 'analyze_skin':
        return l.analyzeSkin;
      case 'skin_symptoms':
        return l.skinSymptoms;
      case 'skin_disclaimer':
        return l.skinDisclaimer;
      case 'result_title':
        return l.resultTitleSkin;
      case 'ask_ai':
        return l.askAi;
      case 'consult':
        return l.contactDoctor;
      case 'book':
        return l.bookAppointment;
      case 'notify':
        return l.contactAsha;
      case 'notified':
        return l.ashaNotified;
      case 'disclaimer':
        return l.screeningDisclaimer;
      case 'possible_condition':
        return l.possibleCondition;
      case 'confidence':
        return l.aiConfidence;
      case 'select_first':
        return l.selectFirst;
      case 'describe_title':
        return l.describeTitle;
      case 'describe_hint':
        return l.describeHint;
      case 'detected':
        return l.symptomsDetected;
      case 'voice_note':
        return l.voiceNote;
      case 'insufficient':
        return l.insufficient;
      case 'insufficient_hint':
        return l.insufficientHint;
      case 'ai_source':
        return l.aiSource;
      case 'analysis_failed':
        return l.analysisFailed;
      case 'speech_denied':
        return l.speechDenied;
      case 'skin_first':
        return l.skinFirst;
      case 'low':
        return l.severityLow;
      case 'moderate':
        return l.severityModerate;
      case 'high':
        return l.severityHigh;
      case 'error_init':
        return l.speechUnavailable;
      default:
        return key;
    }
  }

  String _symptomLabel(SymptomOption option) => option.labelFor(_langCode());

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
    _voice.stop();
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
    final code = LocaleController.instance.languageCode;
    _selectedLanguage =
        code == 'mr' ? 'Marathi' : (code == 'hi' ? 'Hindi' : 'English');
    _localeId = _speechLocaleFor(_selectedLanguage);
  }

  String _speechLocaleFor(String lang) {
    final preferred = lang == 'Marathi'
        ? 'mr-IN'
        : (lang == 'Hindi' ? 'hi-IN' : 'en-IN');
    return _voice.resolveLocaleId(preferred);
  }

  Future<void> _setLanguage(String lang) async {
    setState(() {
      _selectedLanguage = lang;
      _localeId = _speechLocaleFor(lang);
    });
    final code = lang == 'Hindi' ? 'hi' : (lang == 'Marathi' ? 'mr' : 'en');
    await LocaleController.instance.setLanguage(code);
  }

  Future<void> _initSpeech() async {
    try {
      final ok = await _voice.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );
      if (!mounted) return;
      setState(() {
        _localeId = _speechLocaleFor(_selectedLanguage);
        if (!ok) {
          _sttError = _getTxt('error_init');
        }
      });
    } catch (e) {
      debugPrint('Speech init failed: $e');
    }
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    if (status == 'notListening' || status == 'done') {
      setState(() => _isListening = false);
      if (_voiceAnalyzeQueued && _voiceText.trim().isNotEmpty && !_isAnalyzing) {
        _voiceAnalyzeQueued = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _runVoiceToModel();
        });
      }
    } else if (status == 'listening') {
      setState(() => _isListening = true);
    }
  }

  void _onSpeechError(String error) {
    if (!mounted) return;
    setState(() {
      _sttError = error;
      _isListening = false;
    });
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      setState(() {
        _isListening = false;
        _voiceAnalyzeQueued = _voiceText.trim().isNotEmpty;
      });
      await _voice.stop();
      return;
    }

    final allowed = await PermissionDialogService.ensureVoiceInput(context);
    if (!mounted) return;
    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getTxt('speech_denied'))),
      );
      return;
    }

    setState(() {
      _isListening = true;
      _voiceText = '';
      _sttError = '';
      _voiceAnalyzeQueued = false;
      _localeId = _speechLocaleFor(_selectedLanguage);
    });

    final started = await _voice.startListening(
      localeId: _localeId,
      onStatus: _onSpeechStatus,
      onError: _onSpeechError,
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() {
          _voiceText = text;
          _freeTextCtrl.text = text;
          _freeTextCtrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _freeTextCtrl.text.length),
          );
        });
        if (isFinal && text.trim().isNotEmpty) {
          _voiceAnalyzeQueued = true;
        }
      },
    );

    if (!started && mounted) {
      setState(() => _isListening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getTxt('speech_denied'))),
      );
    }
  }

  Future<void> _runVoiceToModel() async {
    if (_isAnalyzing) return;
    await _voice.stop();
    if (!mounted) return;
    _refreshExtractedFromText();
    await _analyzeSymptoms();
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

      var language = _langCode();
      if (freeText.isNotEmpty) {
        language = await LanguageIdService.instance.detect(
          freeText,
          fallback: language,
        );
      }

      await symptomProvider.analyzeSymptoms(
        symptomsText: input,
        recognizedText: _voiceText,
        language: language,
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

  Future<void> _analyzeSkin() async {
    if (_selectedSkinSymptoms.isEmpty) {
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
        language: _langCode(),
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
        aiSource: analysis['result_state']?.toString() ??
            analysis['source']?.toString(),
        rawResult: Map<String, dynamic>.from(analysis),
      ),
    );
  }

  String _screeningSymptomsText() {
    if (_checkerMode == 'skin') return _selectedSkinSymptoms.join(', ');
    return [..._selectedSymptoms, ..._extractedSymptoms].join(', ');
  }

  String _bookingNotes() {
    final analysis =
        Provider.of<SymptomProvider>(context, listen: false).lastAnalysis;
    final finding = analysis?['possible_condition']?.toString() ??
        analysis?['disease']?.toString() ??
        'Elevated-risk screening result';
    final severity = analysis?['severity']?.toString() ?? 'High';
    final symptoms = _screeningSymptomsText();
    final parts = <String>[];
    if (symptoms.trim().isNotEmpty) parts.add(symptoms.trim());
    parts.add('Screening: $finding (risk: $severity). Not a diagnosis.');
    return parts.join('. ');
  }

  void _bookDoctor() {
    Navigator.pushNamed(
      context,
      AppRoutes.bookAppointment,
      arguments: {'symptoms': _bookingNotes()},
    );
  }

  void _escalateHuman() {
    final analysis = Provider.of<SymptomProvider>(context, listen: false).lastAnalysis;
    final finding = analysis?['possible_condition']?.toString() ??
        analysis?['disease']?.toString() ??
        'Elevated-risk screening result';
    final severity = analysis?['severity']?.toString() ?? 'High';
    final symptoms = _screeningSymptomsText();
    final summary = EscalationPolicy.careTeamSummary(
      domain: _resultDomain(),
      possibleFinding: finding,
      severity: severity,
      symptoms: symptoms,
      timestamp: DateTime.now(),
      offlineQueued: analysis?['queued_offline'] == true,
      aiSource: analysis?['source']?.toString(),
    );
    showEscalationSheet(
      context,
      severity: severity,
      isAnimal: false,
      language: _langCode(),
      summary: summary,
      bookingSymptoms: _bookingNotes(),
      forceShow: true,
    );
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
          icon: const Icon(Icons.spa_outlined),
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
                : (_selectedSkinSymptoms.isNotEmpty ? _analyzeSkin : null),
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
                color: _isListening ? Colors.red : AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? Colors.red : AppColors.primary)
                        .withOpacity(0.3),
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
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _getTxt('listening'),
                  style: const TextStyle(
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
    final resultState = analysis['result_state']?.toString() ?? '';
    final isUnresolved = resultState == 'MODEL_ERROR' ||
        resultState == 'INSUFFICIENT_INPUT' ||
        resultState == 'NETWORK_ERROR' ||
        (analysis['insufficient_symptoms'] == true);
    final isFallback = !isUnresolved &&
        (scoreType == 'symptom_match_fallback' ||
            resultState == 'SUCCESS_FALLBACK' ||
            source.contains('dataset'));
    final domain = _resultDomain();
    final symptoms = domain == ScreeningDomain.skin
        ? List<String>.from(_selectedSkinSymptoms)
        : [..._selectedSymptoms, ..._extractedSymptoms];
    final steps = isUnresolved
        ? const <String>[
            'Add clearer symptoms using chips or free text.',
            'Try again once screening completes successfully.',
            'Seek care if you remain worried about your symptoms.',
          ]
        : ScreeningHealthSteps.forResult(
            domain: domain,
            severity: severity,
            condition: disease,
            symptoms: symptoms,
          );
    final band = isUnresolved ? 'Unknown' : EscalationPolicy.normalize(severity);
    final doctorFirst = EscalationPolicy.preferDoctorFirst(band);

    String sourceLabel;
    switch (resultState) {
      case 'SUCCESS_ONDEVICE_ML':
        sourceLabel = 'On-device ML';
        break;
      case 'SUCCESS_SERVER_ML':
        sourceLabel = 'Server ML';
        break;
      case 'SUCCESS_FALLBACK':
        sourceLabel = 'Fallback';
        break;
      case 'MODEL_ERROR':
        sourceLabel = 'Model error';
        break;
      case 'INSUFFICIENT_INPUT':
        sourceLabel = 'Insufficient input';
        break;
      case 'NETWORK_ERROR':
        sourceLabel = 'Network error';
        break;
      default:
        switch (source) {
          case 'skin_cnn_ondevice':
          case 'symptom_mlp_ondevice':
            sourceLabel = 'On-device ML';
            break;
          case 'dataset_local':
          case 'dataset_skin':
          case 'dataset_csv':
            sourceLabel = 'Fallback';
            break;
          case 'model_error':
            sourceLabel = 'Model error';
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
                _escalateHuman();
              } else {
                _bookDoctor();
              }
            }
          : null,
      onContactSecondary: EscalationPolicy.shouldShowEscalationButtons(band)
          ? () {
              final already = analysis['alert_sent'] == true;
              if (!already && !_notifying) {
                _notifyAsha();
              }
              Navigator.pushNamed(context, AppRoutes.ashaWorkers);
            }
          : null,
      onBookDoctor: EscalationPolicy.shouldShowEscalationButtons(band) &&
              doctorFirst
          ? _bookDoctor
          : null,
      primaryContactLabel:
          doctorFirst ? _getTxt('consult') : _getTxt('book'),
      secondaryContactLabel: _getTxt('notify'),
      bookDoctorLabel: _getTxt('book'),
      primaryContactIcon: doctorFirst
          ? Icons.medical_services_outlined
          : Icons.event_available,
      secondaryContactIcon: Icons.health_and_safety_outlined,
      bookDoctorIcon: Icons.event_available,
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
