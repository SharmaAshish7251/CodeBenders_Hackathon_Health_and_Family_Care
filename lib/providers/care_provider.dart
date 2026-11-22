import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/appointment.dart';
import '../models/record.dart';
import '../models/task.dart';
import 'appointments_provider.dart';
import 'family_provider.dart';
import 'session_provider.dart';

/// Records the signed-in user may see in the active family.
class RecordsNotifier extends AsyncNotifier<List<CareRecord>> {
  @override
  Future<List<CareRecord>> build() async {
    final family = await ref.watch(familySpaceProvider.future);
    final user = await ref.watch(currentUserProvider.future);
    if (family == null || user == null) return const [];
    return ref
        .watch(recordRepositoryProvider)
        .list(familyId: family.id, actorId: user.id);
  }

  Future<void> add(CareRecord record) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;
    await ref
        .read(recordRepositoryProvider)
        .create(actorId: user.id, record: record);
    ref.invalidateSelf();
    ref.invalidate(activityProvider);
  }

  Future<void> edit(CareRecord record) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;
    await ref
        .read(recordRepositoryProvider)
        .update(actorId: user.id, record: record);
    ref.invalidateSelf();
    ref.invalidate(activityProvider);
  }

  Future<void> remove(String recordId) async {
    final family = await ref.read(familySpaceProvider.future);
    final user = await ref.read(currentUserProvider.future);
    if (family == null || user == null) return;
    await ref.read(recordRepositoryProvider).delete(
          familyId: family.id,
          actorId: user.id,
          recordId: recordId,
        );
    ref.invalidateSelf();
    ref.invalidate(activityProvider);
  }
}

final recordsProvider =
    AsyncNotifierProvider<RecordsNotifier, List<CareRecord>>(
  RecordsNotifier.new,
);

/// Tasks in the active family, ordered by due time.
class TasksNotifier extends AsyncNotifier<List<CareTask>> {
  @override
  Future<List<CareTask>> build() async {
    final family = await ref.watch(familySpaceProvider.future);
    final user = await ref.watch(currentUserProvider.future);
    if (family == null || user == null) return const [];
    return ref
        .watch(taskRepositoryProvider)
        .list(familyId: family.id, actorId: user.id);
  }

  Future<void> add(CareTask task) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;
    await ref.read(taskRepositoryProvider).create(actorId: user.id, task: task);
    ref.invalidateSelf();
    ref.invalidate(activityProvider);
  }

  /// Saves task fields. Used for snooze, reassign and skip.
  Future<void> edit(CareTask task) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;
    await ref
        .read(taskRepositoryProvider)
        .update(actorId: user.id, task: task);
    ref.invalidateSelf();
    ref.invalidate(activityProvider);
  }

  Future<void> complete(String taskId) async {
    final family = await ref.read(familySpaceProvider.future);
    final user = await ref.read(currentUserProvider.future);
    if (family == null || user == null) return;
    await ref.read(taskRepositoryProvider).complete(
          familyId: family.id,
          actorId: user.id,
          taskId: taskId,
        );
    ref.invalidateSelf();
    ref.invalidate(activityProvider);
  }

  Future<void> remove(String taskId) async {
    final family = await ref.read(familySpaceProvider.future);
    final user = await ref.read(currentUserProvider.future);
    if (family == null || user == null) return;
    await ref.read(taskRepositoryProvider).delete(
          familyId: family.id,
          actorId: user.id,
          taskId: taskId,
        );
    ref.invalidateSelf();
    ref.invalidate(activityProvider);
  }
}

final tasksProvider = AsyncNotifierProvider<TasksNotifier, List<CareTask>>(
  TasksNotifier.new,
);

/// Pending work for the dashboard. Pending means a task with status todo;
/// overdue is a pending task whose due time has passed.
class PendingOverview {
  const PendingOverview({
    required this.overdueCount,
    required this.pendingByAssignee,
  });

  final int overdueCount;

  /// Pending task count keyed by assignee id.
  final Map<String, int> pendingByAssignee;
}

final pendingOverviewProvider = Provider<PendingOverview>((ref) {
  final tasks = ref.watch(tasksProvider).value ?? const <CareTask>[];
  final now = DateTime.now();

  var overdueCount = 0;
  final pendingByAssignee = <String, int>{};
  for (final task in tasks) {
    if (task.status != TaskStatus.todo) continue;
    if (task.dueAt.isBefore(now)) overdueCount++;
    pendingByAssignee.update(
      task.assigneeId,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
  }
  return PendingOverview(
    overdueCount: overdueCount,
    pendingByAssignee: pendingByAssignee,
  );
});

/// Task counts by status for "Care at a glance". The four counts are disjoint:
/// overdue is a todo task whose due time has passed, so it is not in [todo].
class TaskStatusCounts {
  const TaskStatusCounts({
    required this.todo,
    required this.done,
    required this.skipped,
    required this.overdue,
  });

  final int todo;
  final int done;
  final int skipped;
  final int overdue;

  int get total => todo + done + skipped + overdue;
}

final taskStatusCountsProvider = Provider<TaskStatusCounts>((ref) {
  final tasks = ref.watch(tasksProvider).value ?? const <CareTask>[];
  final now = DateTime.now();

  var todo = 0;
  var done = 0;
  var skipped = 0;
  var overdue = 0;
  for (final task in tasks) {
    switch (task.status) {
      case TaskStatus.todo:
        if (task.dueAt.isBefore(now)) {
          overdue++;
        } else {
          todo++;
        }
      case TaskStatus.done:
        done++;
      case TaskStatus.skipped:
        skipped++;
    }
  }
  return TaskStatusCounts(
    todo: todo,
    done: done,
    skipped: skipped,
    overdue: overdue,
  );
});

/// Done tasks per local calendar day for the last 7 days. Index 0 is six days
/// ago and index 6 is today.
final taskCompletedPerDayProvider = Provider<List<int>>((ref) {
  final tasks = ref.watch(tasksProvider).value ?? const <CareTask>[];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final days = [
    for (var i = 0; i < 7; i++)
      DateTime(today.year, today.month, today.day - (6 - i)),
  ];

  final perDay = List<int>.filled(7, 0);
  for (final task in tasks) {
    final completed = task.completedAt;
    if (task.status != TaskStatus.done || completed == null) continue;
    for (var i = 0; i < 7; i++) {
      final day = days[i];
      if (completed.year == day.year &&
          completed.month == day.month &&
          completed.day == day.day) {
        perDay[i]++;
        break;
      }
    }
  }
  return perDay;
});



enum TimelineType { appointment, record, task }

/// One row in the timeline. [personId] is null for appointments, which do
/// not store a person.
class TimelineEntry {
  const TimelineEntry({
    required this.type,
    required this.title,
    required this.at,
    this.personId,
  });

  final TimelineType type;
  final String title;
  final DateTime at;
  final String? personId;
}

/// Timeline filter. Null means "all".
class TimelineFilter {
  const TimelineFilter({this.type, this.personId});

  final TimelineType? type;
  final String? personId;
}

class TimelineFilterNotifier extends Notifier<TimelineFilter> {
  @override
  TimelineFilter build() => const TimelineFilter();

  void setType(TimelineType? type) {
    state = TimelineFilter(type: type, personId: state.personId);
  }

  void setPerson(String? personId) {
    state = TimelineFilter(type: state.type, personId: personId);
  }
}

final timelineFilterProvider =
    NotifierProvider<TimelineFilterNotifier, TimelineFilter>(
  TimelineFilterNotifier.new,
);

/// All timeline entries: appointments, records and completed tasks, newest
/// first.
final timelineProvider = Provider<List<TimelineEntry>>((ref) {
  final appointments = ref.watch(appointmentsProvider);
  final records = ref.watch(recordsProvider).value ?? const <CareRecord>[];
  final tasks = ref.watch(tasksProvider).value ?? const <CareTask>[];

  final entries = <TimelineEntry>[
    for (final Appointment appointment in appointments)
      TimelineEntry(
        type: TimelineType.appointment,
        title: appointment.doctorName,
        at: appointment.dateTime,
      ),
    for (final record in records)
      TimelineEntry(
        type: TimelineType.record,
        title: record.title,
        at: record.date,
        personId: record.uploaderId,
      ),
    for (final task in tasks)
      if (task.status == TaskStatus.done && task.completedAt != null)
        TimelineEntry(
          type: TimelineType.task,
          title: task.title,
          at: task.completedAt ?? task.dueAt,
          personId: task.completedById,
        ),
  ];
  entries.sort((a, b) => b.at.compareTo(a.at));
  return entries;
});

/// Timeline entries after the type and person filters are applied.
final filteredTimelineProvider = Provider<List<TimelineEntry>>((ref) {
  final filter = ref.watch(timelineFilterProvider);
  final entries = ref.watch(timelineProvider);
  return entries.where((entry) {
    if (filter.type != null && entry.type != filter.type) return false;
    if (filter.personId != null && entry.personId != filter.personId) {
      return false;
    }
    return true;
  }).toList();
});
