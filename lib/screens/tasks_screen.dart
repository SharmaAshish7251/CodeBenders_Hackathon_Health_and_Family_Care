import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/role_guard.dart';
import '../l10n/app_localizations.dart';
import '../models/family_member.dart';
import '../models/task.dart';
import '../providers/care_provider.dart';
import '../providers/family_provider.dart';
import '../providers/session_provider.dart';
import '../services/reminder_service.dart';
import '../widgets/care_toast.dart';
import '../widgets/interactive_task_card.dart';
import 'task_detail_sheet.dart';

enum _TaskFilter { all, pending, completed }

/// Modern, elevated Tasks screen with filter chips and interactive task cards.
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  _TaskFilter _filter = _TaskFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tasks = ref.watch(tasksProvider);
    final members = ref.watch(membersProvider).value ?? const <FamilyMember>[];
    final role = ref.watch(currentRoleProvider);
    final canCreate = role != null && canWrite(role, WriteAction.createTask);

    final names = {for (final member in members) member.id: member.name};
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.tasksTitle,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _addTask(context, ref, members),
              icon: const Icon(Icons.add_task),
              label: Text(l10n.taskAddFab),
            )
          : null,
      body: Column(
        children: [
          // Filter Chips Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Tasks'),
                  selected: _filter == _TaskFilter.all,
                  onSelected: (val) => setState(() => _filter = _TaskFilter.all),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Pending'),
                  selected: _filter == _TaskFilter.pending,
                  onSelected: (val) => setState(() => _filter = _TaskFilter.pending),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Completed'),
                  selected: _filter == _TaskFilter.completed,
                  onSelected: (val) => setState(() => _filter = _TaskFilter.completed),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: tasks.when(
              data: (list) {
                final filtered = list.where((task) {
                  return switch (_filter) {
                    _TaskFilter.all => true,
                    _TaskFilter.pending => task.status == TaskStatus.todo,
                    _TaskFilter.completed => task.status == TaskStatus.done,
                  };
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.checklist_rounded,
                          size: 56,
                          color: scheme.outlineVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _filter == _TaskFilter.all
                              ? l10n.tasksEmpty
                              : 'No ${_filter.name} tasks found',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Group by Assignee
                final groups = <String, List<CareTask>>{};
                for (final task in filtered) {
                  groups.putIfAbsent(task.assigneeId, () => []).add(task);
                }

                return ListView(
                  padding: const EdgeInsets.only(bottom: 80, top: 8),
                  children: [
                    for (final entry in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: scheme.primaryContainer,
                              child: Text(
                                (names[entry.key]?.isNotEmpty ?? false)
                                    ? names[entry.key]![0]
                                    : '?',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              names[entry.key] ?? l10n.dashboardUnknownMember,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scheme.primary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${entry.value.length}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (final task in entry.value)
                        InteractiveTaskCard(
                          task: task,
                          assigneeName: names[task.assigneeId],
                          isDueSoon: task.status == TaskStatus.todo &&
                              !task.dueAt.isBefore(now) &&
                              task.dueAt.difference(now).inMinutes <= 30,
                        ),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text(l10n.genericError)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addTask(
    BuildContext context,
    WidgetRef ref,
    List<FamilyMember> members,
  ) async {
    final family = ref.read(familySpaceProvider).value;
    final user = ref.read(currentUserProvider).value;
    if (family == null || user == null) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    final task = await showDialog<CareTask>(
      context: context,
      builder: (dialogContext) => TaskFormDialog(
        familyId: family.id,
        members: members,
        defaultAssigneeId: user.id,
      ),
    );
    if (task == null) return;
    try {
      await ref.read(tasksProvider.notifier).add(task);
      await reminderService.scheduleTaskReminder(
        task,
        body: l10n.taskReminderBody,
      );
      if (context.mounted) {
        CareToast.showSuccess(
          context,
          title: 'Task Created',
          subtitle: task.title,
        );
      }
    } on RoleDeniedException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.actionDeniedMessage)));
    }
  }
}
