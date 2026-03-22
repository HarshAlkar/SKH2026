import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hs053/shared/providers/voice_assistant_provider.dart';
import 'package:hs053/shared/providers/symptom_provider.dart';
import 'voice_assistant_overlay.dart';

class VoiceAssistantFab extends StatelessWidget {
  const VoiceAssistantFab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceAssistantProvider>(
      builder: (context, provider, child) {
        return FloatingActionButton(
          onPressed: () {
            _showVoiceAssistant(context);
          },
          backgroundColor: const Color(0xFF2F4DB6),
          child: const Icon(Icons.mic, color: Colors.white),
        );
      },
    );
  }

  void _showVoiceAssistant(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VoiceAssistantOverlay(),
    );
  }
}
