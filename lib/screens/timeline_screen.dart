import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/family_member.dart';
import '../providers/care_provider.dart';
import '../providers/family_provider.dart';
import '../widgets/care_labels.dart';

/// Connected chronological timeline of appointments, records and completed tasks (PRD F4).
class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final filter = ref.watch(timelineFilterProvider);
    final entries = ref.watch(filteredTimelineProvider);
    final members = ref.watch(membersProvider).value ?? const <FamilyMember>[];
    final names = {for (final member in members) member.id: member.name};
    final filterNotifier = ref.read(timelineFilterProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.timelineTitle,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Chips Horizontal Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: Text(l10n.timelineFilterAll),
                  selected: filter.type == null,
                  onSelected: (_) => filterNotifier.setType(null),
                ),
                const SizedBox(width: 8),
                for (final type in TimelineType.values) ...[
                  FilterChip(
                    label: Text(timelineTypeLabel(l10n, type)),
                    selected: filter.type == type,
                    onSelected: (_) => filterNotifier.setType(type),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timeline_rounded, size: 56, color: scheme.outlineVariant),
                        const SizedBox(height: 12),
                        Text(
                          l10n.timelineEmpty,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final isFirst = index == 0;
                      final isLast = index == entries.length - 1;

                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Connected Node Indicator
                            SizedBox(
                              width: 36,
                              child: Column(
                                children: [
                                  Container(
                                    width: 2,
                                    height: isFirst ? 8 : 16,
                                    color: isFirst ? Colors.transparent : scheme.outlineVariant,
                                  ),
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: _nodeColor(entry.type, scheme),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _icon(entry.type),
                                      size: 14,
                                      color: _iconColor(entry.type, scheme),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      width: 2,
                                      color: isLast ? Colors.transparent : scheme.outlineVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Event Card
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: scheme.surfaceContainerHighest,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                timelineTypeLabel(l10n, entry.type).toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                  color: scheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              formatDateTime(entry.at),
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: scheme.onSurfaceVariant,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          entry.title,
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (entry.personId != null && names[entry.personId] != null) ...[
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(Icons.person_outline, size: 14, color: scheme.primary),
                                              const SizedBox(width: 4),
                                              Text(
                                                names[entry.personId]!,
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: scheme.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _nodeColor(TimelineType type, ColorScheme scheme) {
    return switch (type) {
      TimelineType.appointment => const Color(0xFFE3F2FD),
      TimelineType.record => const Color(0xFFE8F5E9),
      TimelineType.task => const Color(0xFFEDE7F6),
    };
  }

  Color _iconColor(TimelineType type, ColorScheme scheme) {
    return switch (type) {
      TimelineType.appointment => const Color(0xFF1565C0),
      TimelineType.record => const Color(0xFF2E7D32),
      TimelineType.task => const Color(0xFF512DA8),
    };
  }

  IconData _icon(TimelineType type) {
    return switch (type) {
      TimelineType.appointment => Icons.event_rounded,
      TimelineType.record => Icons.description_rounded,
      TimelineType.task => Icons.check_circle_rounded,
    };
  }
}
