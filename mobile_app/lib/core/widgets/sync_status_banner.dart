import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../sync/sync_service.dart';
import '../sync/sync_status.dart';

class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncStatus>(
      builder: (context, sync, _) {
        if (sync.isOnline && sync.pendingCount == 0 && !sync.isSyncing) {
          return const SizedBox.shrink();
        }

        final Color color;
        final String text;
        if (!sync.isOnline) {
          color = const Color(0xFFB45309);
          text = sync.pendingCount > 0
              ? 'Offline — ${sync.pendingCount} item(s) saved on phone'
              : 'Offline — showing last saved data';
        } else if (sync.isSyncing || sync.pendingCount > 0) {
          color = const Color(0xFF1D4ED8);
          text = sync.isSyncing
              ? 'Syncing ${sync.pendingCount} item(s) to cloud…'
              : '${sync.pendingCount} item(s) waiting to sync';
        } else {
          return const SizedBox.shrink();
        }

        return Material(
          color: color,
          child: InkWell(
            onTap: () => SyncService.instance.flush(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (sync.isSyncing)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    Icon(
                      sync.isOnline ? Icons.cloud_upload_outlined : Icons.cloud_off,
                      color: Colors.white,
                      size: 16,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (sync.isOnline && sync.pendingCount > 0)
                    const Text(
                      'TAP TO RETRY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
