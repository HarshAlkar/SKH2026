import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/services/language_manager.dart';
import '../../../core/theme/app_colors.dart';
import '../services/ai_service.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  final AIService _aiService = AIService();

  bool _isListening = false;
  String _text = 'Press the button and start speaking';
  String _response = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    _initTTS();
  }

  Future<void> _initTTS() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
             setState(() => _isListening = false);
             if (_text != 'Press the button and start speaking' && _text.isNotEmpty) {
               _getAIResponse(_text);
             }
          }
           print('onStatus: $val');
        },
        onError: (val) {
          print('onError: $val');
          setState(() => _isListening = false);
        },
      );
      if (available) {
        setState(() => _isListening = true);
        final lang = context.read<LanguageManager>().currentLang;
        String locale = 'en_US';
        if (lang == 'hi') locale = 'hi_IN';
        if (lang == 'mr') locale = 'mr_IN';

        _speech.listen(
          localeId: locale,
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _getAIResponse(String query) async {
    setState(() {
      _isLoading = true;
      _response = 'Analyzing...';
    });

    final lang = context.read<LanguageManager>().currentLang;
    try {
      final aiRes = await _aiService.getAIResponse(query, lang: lang);
      setState(() {
        _response = aiRes;
        _isLoading = false;
      });
      _speak(aiRes);
    } catch (e) {
      setState(() {
        _response = "Sorry, I couldn't process that. Check your connection or offline data.";
        _isLoading = false;
      });
    }
  }

  Future<void> _speak(String text) async {
    final lang = context.read<LanguageManager>().currentLang;
    if (lang == 'hi') await _tts.setLanguage("hi-IN");
    else if (lang == 'mr') await _tts.setLanguage("hi-IN"); // Marathi TTS fallback to Hindi if not available
    else await _tts.setLanguage("en-US");
    
    await _tts.speak(text);
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langManager = context.watch<LanguageManager>();
    final curLang = langManager.currentLang;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Assistant'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        actions: [
          DropdownButton<String>(
            value: curLang,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'en', child: Text('EN')),
              DropdownMenuItem(value: 'hi', child: Text('HI')),
              DropdownMenuItem(value: 'mr', child: Text('MR')),
            ],
            onChanged: (val) {
               if (val != null) langManager.setLanguage(val);
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.withOpacity(0.1)),
                ),
                child: SingleChildScrollView(
                  reverse: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You: ',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _text,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 24),
                      if (_response.isNotEmpty) ...[
                        const Text(
                          'Assistant: ',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _response,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            _buildListeningAnimation(),
            const SizedBox(height: 20),
            Text(
              _isListening ? "Listening..." : "Tap to Speak",
              style: TextStyle(
                color: _isListening ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildListeningAnimation() {
    return AvatarGlow(
      animate: _isListening,
      glowColor: AppColors.primary,
      duration: const Duration(milliseconds: 2000),
      repeat: true,
      child: GestureDetector(
        onTap: _listen,
        child: CircleAvatar(
          backgroundColor: AppColors.primary,
          radius: 35,
          child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
