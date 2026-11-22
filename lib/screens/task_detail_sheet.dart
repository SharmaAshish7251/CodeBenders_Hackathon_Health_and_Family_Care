import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/role_guard.dart';
import '../l10n/app_localizations.dart';
import '../models/family_member.dart';
import '../models/task.dart';
import '../providers/family_provider.dart';
import '../providers/care_provider.dart';
import '../providers/session_provider.dart';
import '../repositories/analytics_repository.dart';
import '../services/reminder_service.dart';
import '../widgets/care_labels.dart';
import '../widgets/care_toast.dart';

/// Bottom sheet for one task: Edit, Complete, Snooze, Reassign, skip and delete.
/// Each action is checked against the role guard. The UI hides controls the
/// user cannot use, and a denied action shows a message.
class TaskDetailSheet extends ConsumerWidget {
  const TaskDetailSheet({super.key, required this.task});

  final CareTask task;

  static Future<void> show(BuildContext context, CareTask task) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => TaskDetailSheet(task: task),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final role = ref.watch(currentRoleProvider);
    final userId = ref.watch(currentUserProvider).value?.id;
    final members = ref.watch(membersProvider).value ?? const <FamilyMember>[];
    final assigneeName = _memberName(members, task.assigneeId);
    final isOpen = task.status == TaskStatus.todo;

    final canAct = role != null && userId != null;
    final canEdit = canAct &&
        canWrite(role, WriteAction.updateTask) &&
        canCompleteTask(role, task.assigneeId, userId);
    final canComplete = canAct &&
        canWrite(role, WriteAction.completeTask) &&
        canCompleteTask(role, task.assigneeId, userId);
    // Only admins and caregivers hand tasks to someone else.
    final canReassign = canEdit && role != Role.delegate;
    final canDelete = canAct && canWrite(role, WriteAction.deleteTask);
    final canEditTask = canAct && canWrite(role, WriteAction.updateTask);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Title + Status Pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (task.description != null && task.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: switch (task.status) {
                      TaskStatus.done => const Color(0xFFE8F5E9),
                      TaskStatus.todo => const Color(0xFFFFF3E0),
                      TaskStatus.skipped => theme.colorScheme.surfaceContainerHighest,
                    },
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    taskStatusLabel(l10n, task.status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: switch (task.status) {
                        TaskStatus.done => const Color(0xFF2E7D32),
                        TaskStatus.todo => const Color(0xFFE65100),
                        TaskStatus.skipped => theme.colorScheme.onSurfaceVariant,
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Metadata Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Text(
                        'Due: ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        formatDateTime(task.dueAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          recurrenceLabel(l10n, task.recurrence),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Text(
                        'Assignee: ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        assigneeName ?? l10n.taskUnassigned,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (task.completedAt != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 10),
                        Text(
                          'Completed by: ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${_memberName(members, task.completedById ?? '') ?? '-'} • ${formatDateTime(task.completedAt!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Actions
            if (isOpen && canComplete) ...[
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.check_circle_outline),
                onPressed: () => _run(context, () async {
                  final oldStatus = task.status;
                  await ref.read(tasksProvider.notifier).complete(task.id);
                  await reminderService.cancelTaskReminder(task.id);
                  ref.read(analyticsRepositoryProvider).log(AnalyticsEvents.taskCompleted);
                  if (context.mounted) {
                    CareToast.showTaskCompleted(
                      context,
                      taskTitle: task.title,
                      onUndo: () async {
                        await ref.read(tasksProvider.notifier).edit(
                              task.copyWith(status: oldStatus, completedAt: null),
                            );
                      },
                    );
                  }
                }),
                label: Text(
                  l10n.taskCompleteAction,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Secondary Quick Action Buttons
            if (isOpen)
              Row(
                children: [
                  if (canEdit)
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.snooze, size: 16),
                        onPressed: () => _run(context, () async {
                          final newDue = task.dueAt.add(const Duration(hours: 1));
                          await ref
                              .read(tasksProvider.notifier)
                              .edit(task.copyWith(dueAt: newDue));
                          if (context.mounted) {
                            CareToast.showTaskSnoozed(
                              context,
                              taskTitle: task.title,
                              newDueText: formatDateTime(newDue),
                            );
                          }
                        }),
                        label: Text(l10n.taskSnoozeAction, style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  if (canEdit && canReassign) const SizedBox(width: 8),
                  if (canReassign)
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.swap_horiz, size: 16),
                        onPressed: () => _reassign(context, ref, members),
                        label: Text(l10n.taskReassignAction, style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  if (canEdit) const SizedBox(width: 8),
                  if (canEdit)
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.skip_next, size: 16),
                        onPressed: () => _run(context, () async {
                          await ref
                              .read(tasksProvider.notifier)
                              .edit(task.copyWith(status: TaskStatus.skipped));
                          if (context.mounted) {
                            CareToast.showTaskSkipped(
                              context,
                              taskTitle: task.title,
                            );
                          }
                        }),
                        label: Text(l10n.taskSkipAction, style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 8),

            // Edit & Delete row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (canEditTask)
                  TextButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () =>
                        _edit(context, ref, members, role != Role.delegate),
                    label: Text(l10n.taskEditAction),
                  ),
                if (canDelete)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => _confirmDelete(context, ref),
                    label: Text(l10n.taskDeleteAction),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _memberName(List<FamilyMember> members, String id) {
    for (final member in members) {
      if (member.id == id) return member.name;
    }
    return null;
  }

  /// Runs [action], closes the sheet on success, and shows a message when the
  /// role guard denies it.
  Future<void> _run(BuildContext context, Future<void> Function() action) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      if (context.mounted) Navigator.of(context).pop();
    } on RoleDeniedException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.actionDeniedMessage)));
    }
  }

  /// Opens the task form pre-filled with this task and saves the result.
  /// Delegates cannot hand tasks to someone else, so their form has no
  /// assignee picker.
  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    List<FamilyMember> members,
    bool allowReassign,
  ) async {
    final updated = await showDialog<CareTask>(
      context: context,
      builder: (dialogContext) => TaskFormDialog(
        familyId: task.familyId,
        members: members,
        defaultAssigneeId: task.assigneeId,
        existing: task,
        allowReassign: allowReassign,
      ),
    );
    if (updated == null || !context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    await _run(context, () async {
      await ref.read(tasksProvider.notifier).edit(updated);
      await reminderService.scheduleTaskReminder(
        updated,
        body: l10n.taskReminderBody,
      );
      if (context.mounted) {
        CareToast.showSuccess(
          context,
          title: 'Task Updated',
          subtitle: updated.title,
        );
      }
    });
  }

  /// Asks for confirmation before deleting. Only a confirmed delete runs.
  /// Cancel closes the dialog only, so the sheet stays open.
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.taskDeleteConfirmTitle),
        content: Text(l10n.taskDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.taskDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _run(context, () async {
      await ref.read(tasksProvider.notifier).remove(task.id);
      await reminderService.cancelTaskReminder(task.id);
      if (context.mounted) {
        CareToast.showSuccess(
          context,
          title: 'Task Removed',
          subtitle: task.title,
        );
      }
    });
  }

  Future<void> _reassign(
    BuildContext context,
    WidgetRef ref,
    List<FamilyMember> members,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.taskReassignTitle),
        children: [
          for (final member in members)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(member.id),
              child: Text(member.name),
            ),
        ],
      ),
    );
    if (picked == null || !context.mounted) return;
    final targetMember = members.firstWhere((m) => m.id == picked, orElse: () => members.first);
    await _run(context, () async {
      await ref
          .read(tasksProvider.notifier)
          .edit(task.copyWith(assigneeId: picked));
      if (context.mounted) {
        CareToast.showSuccess(
          context,
          title: 'Task Reassigned',
          subtitle: '${task.title} → ${targetMember.name}',
        );
      }
    });
  }
}

/// Form for creating a task, or editing one when [existing] is given.
class TaskFormDialog extends StatefulWidget {
  const TaskFormDialog({
    super.key,
    required this.familyId,
    required this.members,
    required this.defaultAssigneeId,
    this.existing,
    this.allowReassign = true,
  });

  final String familyId;
  final List<FamilyMember> members;
  final String defaultAssigneeId;
  final CareTask? existing;
  final bool allowReassign;

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController =
      TextEditingController(text: widget.existing?.title ?? '');
  late final _descriptionController =
      TextEditingController(text: widget.existing?.description ?? '');
  late DateTime _dueAt =
      widget.existing?.dueAt ?? DateTime.now().add(const Duration(hours: 1));
  late String _assigneeId = widget.defaultAssigneeId;
  late Recurrence _recurrence = widget.existing?.recurrence ?? Recurrence.none;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt),
    );
    if (time == null) return;
    setState(() {
      _dueAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _save() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    final description = _descriptionController.text.trim();
    final existing = widget.existing;
    Navigator.of(context).pop(
      CareTask(
        id: existing?.id ?? newEntityId(),
        familyId: widget.familyId,
        title: _titleController.text.trim(),
        description: description.isEmpty ? null : description,
        dueAt: _dueAt,
        assigneeId: _assigneeId,
        status: existing?.status ?? TaskStatus.todo,
        recurrence: _recurrence,
        completedById: existing?.completedById,
        completedAt: existing?.completedAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(
        widget.existing == null ? l10n.taskNewTitle : l10n.taskEditTitle,
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: l10n.taskTitleLabel),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? l10n.fieldRequired : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration:
                    InputDecoration(labelText: l10n.taskDescriptionLabel),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.taskDueLabel),
                subtitle: Text(formatDateTime(_dueAt)),
                trailing: const Icon(Icons.schedule),
                onTap: _pickDueAt,
              ),
              if (widget.allowReassign)
                DropdownButtonFormField<String>(
                  initialValue: _assigneeId,
                  decoration:
                      InputDecoration(labelText: l10n.taskAssigneeLabel),
                  items: [
                    for (final member in widget.members)
                      DropdownMenuItem(
                        value: member.id,
                        child: Text(member.name),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _assigneeId = value);
                  },
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Recurrence>(
                initialValue: _recurrence,
                decoration: InputDecoration(labelText: l10n.taskRecurrenceLabel),
                items: [
                  for (final recurrence in Recurrence.values)
                    DropdownMenuItem(
                      value: recurrence,
                      child: Text(recurrenceLabel(l10n, recurrence)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _recurrence = value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelAction),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.saveAction)),
      ],
    );
  }
}
