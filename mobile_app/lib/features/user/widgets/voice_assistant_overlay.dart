import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hs053/shared/providers/voice_assistant_provider.dart';
import 'package:hs053/shared/providers/symptom_provider.dart';

class VoiceAssistantOverlay extends StatefulWidget {
  const VoiceAssistantOverlay({super.key});

  @override
  State<VoiceAssistantOverlay> createState() => _VoiceAssistantOverlayState();
}

class _VoiceAssistantOverlayState extends State<VoiceAssistantOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VoiceAssistantProvider>(context);
    final symptomProvider = Provider.of<SymptomProvider>(context, listen: false);

    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Handle bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () {
                  provider.reset();
                  Navigator.pop(context);
                },
              ),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 48), // Spacer for centering handle
            ],
          ),
          
          // Header with Language Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Health Assistant',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F4DB6),
                ),
              ),
              _buildLanguageSelector(provider),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Transcription Text (User input)
          if (provider.transcribedText.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F1FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                provider.transcribedText,
                style: const TextStyle(fontSize: 16, color: Color(0xFF1E293B)),
              ),
            ),

          // Response Text (AI output)
          if (provider.responseMessage.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 16, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'AI Response',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.responseMessage,
                    style: TextStyle(fontSize: 15, color: Colors.green.shade900),
                  ),
                ],
              ),
            ),
          
          const Spacer(),
          
          // Mid Section: Status Icon and Text
          _buildStatusArea(provider),
          
          const Spacer(),
          
          // Mic Button
          _buildMicButton(provider, symptomProvider),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(VoiceAssistantProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2F4DB6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LanguageOption>(
          value: provider.currentLanguage,
          onChanged: (lang) => provider.setLanguage(lang!),
          items: provider.languages.map((lang) {
            return DropdownMenuItem(
              value: lang,
              child: Text(
                lang.name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF2F4DB6)),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  Widget _buildStatusArea(VoiceAssistantProvider provider) {
    String text = "Tell me how you are feeling...";
    IconData icon = Icons.mic_none;
    Color color = Colors.grey;

    switch (provider.state) {
      case AssistantState.listening:
        text = "I'm listening...";
        icon = Icons.hearing;
        color = Colors.blue;
        break;
      case AssistantState.processing:
        text = "Processing...";
        icon = Icons.hourglass_empty;
        color = Colors.orange;
        break;
      case AssistantState.speaking:
        text = "Responding...";
        icon = Icons.volume_up;
        color = Colors.green;
        break;
      case AssistantState.error:
        text = provider.lastError;
        icon = Icons.warning_amber_rounded;
        color = Colors.red;
        break;
      default:
        break;
    }

    return Column(
      children: [
        if (provider.state == AssistantState.processing)
          const CircularProgressIndicator(strokeWidth: 2)
        else
          Icon(icon, color: color, size: 40),
        const SizedBox(height: 12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMicButton(VoiceAssistantProvider provider, SymptomProvider symptomProvider) {
    bool isListening = provider.state == AssistantState.listening;
    bool isSpeaking = provider.state == AssistantState.speaking;
    
    return GestureDetector(
      onTap: () => provider.toggleListening(symptomProvider),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isListening)
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  width: 90 + (30 * _animationController.value),
                  height: 90 + (30 * _animationController.value),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F4DB6).withOpacity(0.3 * (1 - _animationController.value)),
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isSpeaking ? Colors.green : const Color(0xFF2F4DB6),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isSpeaking ? Colors.green : const Color(0xFF2F4DB6)).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              isListening ? Icons.stop : (isSpeaking ? Icons.volume_off : Icons.mic),
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }
}
