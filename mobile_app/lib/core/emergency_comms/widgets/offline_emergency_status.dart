import 'package:flutter/material.dart';

import '../emergency_comms.dart';

class OfflineEmergencyStatusTile extends StatelessWidget {
  const OfflineEmergencyStatusTile({super.key});

  @override
  Widget build(BuildContext context) {
    final comms = EmergencyComms.instance;
    return ListenableBuilder(
      listenable: comms,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            'Offline emergency: ${comms.mode.wireName}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        );
      },
    );
  }
}
