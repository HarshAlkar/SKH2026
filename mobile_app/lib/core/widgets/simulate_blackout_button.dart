import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../sync/blackout_recovery.dart';

/// Live-demo: wipes phone primary DB AND triggers backend blackout (terminal + display).
class SimulateBlackoutButton extends StatefulWidget {
  const SimulateBlackoutButton({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  State<SimulateBlackoutButton> createState() => _SimulateBlackoutButtonState();
}

class _SimulateBlackoutButtonState extends State<SimulateBlackoutButton> {
  bool _busy = false;

  Future<void> _run() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      // 1) Phone local primary wipe + shadow restore
      final local = await BlackoutRecovery.instance.simulateBlackout();

      // 2) Server clinical table wipe + shadow restore (shows on Django terminal + /blackout/display/)
      String serverMsg = '';
      try {
        final res = await ApiService().post('/blackout/simulate/', body: {});
        if (res is Map) {
          final recovered = res['recovered'] ?? 0;
          final primary = res['primary_count'] ?? 0;
          serverMsg =
              'Server recovered $recovered screening(s) → DB count=$primary';
        } else {
          serverMsg = 'Server blackout OK';
        }
      } catch (e) {
        serverMsg = 'Server blackout skipped (is Django running?): $e';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Phone: recovered ${local.recoveredOutbox} pending. $serverMsg',
          ),
          backgroundColor: const Color(0xFF991B1B),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Blackout simulate failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return IconButton(
        tooltip: 'Simulate Blackout (wipe primary DB)',
        onPressed: _busy ? null : _run,
        icon: _busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.bolt, color: Color(0xFF991B1B)),
      );
    }

    return OutlinedButton.icon(
      onPressed: _busy ? null : _run,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF991B1B),
        side: const BorderSide(color: Color(0xFF991B1B)),
      ),
      icon: _busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.bolt, size: 18),
      label: Text(_busy ? 'Recovering…' : 'Simulate Blackout'),
    );
  }
}
