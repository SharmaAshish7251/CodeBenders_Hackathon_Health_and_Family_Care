import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/activity_event.dart';
import '../models/family_member.dart';
import '../models/medicine.dart';
import '../models/record.dart';
import '../models/task.dart';
import '../providers/appointments_provider.dart';
import '../providers/care_provider.dart';
import '../providers/family_provider.dart';
import '../providers/medicine_provider.dart';
import '../providers/session_provider.dart';
import '../repositories/analytics_repository.dart';
import '../services/summary_builder.dart';

/// Shows a plain-text care summary styled like a WhatsApp chat card (PRD F8).
class SummaryDialog extends ConsumerWidget {
  const SummaryDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const SummaryDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final family = ref.watch(familySpaceProvider).value;
    final members = ref.watch(membersProvider).value ?? const <FamilyMember>[];
    final tasks = ref.watch(tasksProvider).value ?? const <CareTask>[];
    final records = ref.watch(recordsProvider).value ?? const <CareRecord>[];
    final medicines = ref.watch(medicinesProvider).value ?? const <Medicine>[];
    final activity =
        ref.watch(activityProvider).value ?? const <ActivityEvent>[];
    final appointments = ref.watch(appointmentsProvider);

    final summary = buildCareSummary(
      l10n: l10n,
      recipientName: family?.name ?? 'Care Recipient',
      now: DateTime.now(),
      tasks: tasks,
      records: records,
      medicines: medicines,
      activity: activity,
      memberNames: {for (final member in members) member.id: member.name},
      appointments: appointments,
    );

    final messenger = ScaffoldMessenger.of(context);
    final copiedMessage = l10n.summaryCopiedMessage;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WhatsApp Care Update',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Plain-language family update',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // WhatsApp-style message bubble
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEAE2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDAD2C7)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: SelectableText(
                            summary,
                            style: const TextStyle(
                              color: Color(0xFF111B21),
                              fontSize: 13,
                              height: 1.45,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                l10n.summaryExcludesNote,
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.closeAction),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text(
                        'Copy Summary',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        ref.read(analyticsRepositoryProvider).log(AnalyticsEvents.summaryShared);
                        await Clipboard.setData(ClipboardData(text: summary));
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(copiedMessage),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
