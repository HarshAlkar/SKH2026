import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/doctor/screens/my_patients_screen.dart';
import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import 'emergency_comms.dart';
import 'emergency_packet.dart';

/// Listens for offline emergency packets and shows a blocking dialog on
/// doctor/ASHA devices. Independent of NotificationService / Django alerts.
class EmergencyAlertHost {
  EmergencyAlertHost._();
  static final EmergencyAlertHost instance = EmergencyAlertHost._();

  StreamSubscription<EmergencyPacket>? _sub;
  bool _dialogOpen = false;
  final Set<String> _shown = <String>{};

  void start() {
    _sub?.cancel();
    _sub = EmergencyComms.instance.incoming.listen(_onPacket);
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  Future<void> _onPacket(EmergencyPacket packet) async {
    if (_shown.contains(packet.packetId)) return;
    _shown.add(packet.packetId);

    final context = navigatorKey.currentContext;
    final nav = navigatorKey.currentState;
    if (context == null || nav == null) return;

    final role = context.read<AuthProvider>().user?.role ?? '';
    if (role != 'doctor' && role != 'asha_worker') {
      debugPrint('EMERGENCY [ui] ignore rx for role=$role');
      return;
    }

    if (_dialogOpen && nav.canPop()) {
      nav.pop();
      _dialogOpen = false;
    }

    _dialogOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EmergencyIncomingDialog(packet: packet),
    );
    _dialogOpen = false;
  }
}

class EmergencyIncomingDialog extends StatelessWidget {
  const EmergencyIncomingDialog({super.key, required this.packet});

  final EmergencyPacket packet;

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFE53935);
    final when = DateTime.fromMillisecondsSinceEpoch(packet.timestamp * 1000);
    final location = packet.locationLabel.isEmpty ? 'Not available' : packet.locationLabel;
    final role = context.read<AuthProvider>().user?.role ?? '';
    final phone = packet.phone?.trim() ?? '';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFFFFE9E9),
                    child: Icon(Icons.emergency, color: red),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'OFFLINE EMERGENCY',
                      style: TextStyle(
                        color: red,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _row('Patient', packet.name.isEmpty ? 'Unknown' : packet.name),
              _row('Patient ID', packet.patientId == 0 ? '—' : '${packet.patientId}'),
              if (packet.age != null) _row('Age', '${packet.age}'),
              _row('Type', packet.type.toUpperCase()),
              _row('Priority', '${packet.priority} / 9'),
              _row('Time', when.toLocal().toString().split('.').first),
              _row('Location', location),
              if (packet.village.isNotEmpty) _row('Village', packet.village),
              _row('Packet', packet.packetId),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: red,
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: () async {
                  await EmergencyComms.instance.acknowledge(packet);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Acknowledge'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _openPatient(context, role);
                },
                child: const Text('View Patient'),
              ),
              TextButton.icon(
                onPressed: phone.isEmpty ? null : () => _call(phone),
                icon: const Icon(Icons.phone),
                label: Text(phone.isEmpty ? 'No phone on packet' : 'Contact $phone'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _openPatient(BuildContext context, String role) {
    if (packet.patientId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No patient id on this packet')),
      );
      return;
    }
    if (role == 'asha_worker') {
      Navigator.pushNamed(context, AppRoutes.villagePatients);
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPatientsScreen()));
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
