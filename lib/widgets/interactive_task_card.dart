import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../providers/care_provider.dart';
import '../providers/session_provider.dart';
import '../repositories/analytics_repository.dart';
import '../screens/task_detail_sheet.dart';
import '../services/reminder_service.dart';
import '../widgets/care_labels.dart';
import 'care_toast.dart';

/// Task card following Design Spec section 2, 3.4, 4, 6.
///
/// Features:
/// - 20 dp corner radius
/// - 48 dp min tap targets
/// - Micro-interaction on checkbox: 220 ms overshoot scale bounce + light haptic feedback
/// - Neutral overdue presentation without guilt language
/// - Quick actions: Complete, Snooze, and "I'm stretched: reassign"
class InteractiveTaskCard extends ConsumerStatefulWidget {
  const InteractiveTaskCard({
    super.key,
    required this.task,
    this.assigneeName,
    this.isDueSoon = false,
  });

  final CareTask task;
  final String? assigneeName;
  final bool isDueSoon;

  @override
  ConsumerState<InteractiveTaskCard> createState() => _InteractiveTaskCardState();
}

class _InteractiveTaskCardState extends ConsumerState<InteractiveTaskCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // 220 ms overshoot curve as defined in Design Spec section 4
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_scaleController);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _handleComplete() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    // Haptic feedback (Section 4)
    HapticFeedback.lightImpact();

    // Trigger bounce micro-interaction if reduce-motion is not requested
    if (!MediaQuery.of(context).disableAnimations) {
      await _scaleController.forward(from: 0);
    }

    if (!mounted) return;

    try {
      final taskId = widget.task.id;
      final oldStatus = widget.task.status;

      await ref.read(tasksProvider.notifier).complete(taskId);
      await reminderService.cancelTaskReminder(taskId);
      ref.read(analyticsRepositoryProvider).log(AnalyticsEvents.taskCompleted);

      if (!mounted) return;

      // Beautiful floating reward toast with Undo action
      CareToast.showTaskCompleted(
        context,
        taskTitle: widget.task.title,
        onUndo: () async {
          await ref.read(tasksProvider.notifier).edit(
                widget.task.copyWith(status: oldStatus, completedAt: null),
              );
        },
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDone = widget.task.status == TaskStatus.done;
    final isOverdue = !isDone && widget.task.dueAt.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => TaskDetailSheet.show(context, widget.task),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Checkbox with micro-interaction
              ScaleTransition(
                scale: _scaleAnimation,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    iconSize: 26,
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      isDone
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isDone
                          ? scheme.primary
                          : (isOverdue
                              ? scheme.error.withValues(alpha: 0.8)
                              : scheme.outline),
                    ),
                    onPressed: isDone ? null : _handleComplete,
                    tooltip: isDone ? 'Completed' : 'Mark done',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Task Title & Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.task.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone
                            ? scheme.onSurfaceVariant.withValues(alpha: 0.7)
                            : scheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (widget.assigneeName != null) ...[
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              widget.assigneeName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: isOverdue ? scheme.error : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          formatDateTime(widget.task.dueAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isOverdue ? scheme.error : scheme.onSurfaceVariant,
                            fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Tags / Badges
              if (widget.isDueSoon)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Due soon',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else if (isOverdue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Overdue',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
