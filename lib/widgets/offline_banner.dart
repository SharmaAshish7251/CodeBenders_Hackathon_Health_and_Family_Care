import 'package:flutter/material.dart';

enum SyncStatus { online, syncing, offline }

/// Shows offline or syncing status without hiding cached data (Design Spec section 6 & 7).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    this.status = SyncStatus.online,
  });

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == SyncStatus.online) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isSyncing = status == SyncStatus.syncing;

    final bgColor = isSyncing
        ? scheme.secondaryContainer
        : scheme.surfaceContainerHighest;
    final fgColor = isSyncing
        ? scheme.onSecondaryContainer
        : scheme.onSurfaceVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            isSyncing ? Icons.sync : Icons.cloud_off_outlined,
            size: 16,
            color: fgColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isSyncing
                  ? 'Syncing changes with family...'
                  : 'Working offline. Your cached records and tasks are ready.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: fgColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
