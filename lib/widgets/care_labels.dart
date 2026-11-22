import '../l10n/app_localizations.dart';
import '../models/family_member.dart';
import '../models/task.dart';
import '../providers/care_provider.dart';
import '../repositories/activity_repository.dart';

/// Localised label for a role.
String roleLabel(AppLocalizations l10n, Role role) {
  return switch (role) {
    Role.admin => l10n.roleAdmin,
    Role.caregiver => l10n.roleCaregiver,
    Role.viewer => l10n.roleViewer,
    Role.delegate => l10n.roleDelegate,
  };
}

/// Localised label for a task status.
String taskStatusLabel(AppLocalizations l10n, TaskStatus status) {
  return switch (status) {
    TaskStatus.todo => l10n.taskStatusTodo,
    TaskStatus.done => l10n.taskStatusDone,
    TaskStatus.skipped => l10n.taskStatusSkipped,
  };
}

/// Localised label for a task recurrence.
String recurrenceLabel(AppLocalizations l10n, Recurrence recurrence) {
  return switch (recurrence) {
    Recurrence.none => l10n.recurrenceNone,
    Recurrence.daily => l10n.recurrenceDaily,
    Recurrence.weekly => l10n.recurrenceWeekly,
    Recurrence.monthly => l10n.recurrenceMonthly,
  };
}

/// Localised label for a timeline type filter.
String timelineTypeLabel(AppLocalizations l10n, TimelineType type) {
  return switch (type) {
    TimelineType.appointment => l10n.timelineTypeAppointment,
    TimelineType.record => l10n.timelineTypeRecord,
    TimelineType.task => l10n.timelineTypeTask,
  };
}

/// Localised sentence for a stored activity action code. Unknown codes fall
/// back to the generic error text rather than showing raw data.
String activityLabel(AppLocalizations l10n, String action) {
  return switch (action) {
    ActivityActions.familyCreated => l10n.activityFamilyCreated,
    ActivityActions.memberRoleChanged => l10n.activityMemberRoleChanged,
    ActivityActions.memberJoined => l10n.activityMemberJoined,
    ActivityActions.memberRemoved => l10n.activityMemberRemoved,
    ActivityActions.recordCreated => l10n.activityRecordCreated,
    ActivityActions.recordUpdated => l10n.activityRecordUpdated,
    ActivityActions.recordDeleted => l10n.activityRecordDeleted,
    ActivityActions.taskCreated => l10n.activityTaskCreated,
    ActivityActions.taskUpdated => l10n.activityTaskUpdated,
    ActivityActions.taskCompleted => l10n.activityTaskCompleted,
    ActivityActions.taskDeleted => l10n.activityTaskDeleted,
    _ => l10n.genericError,
  };
}

/// Formats a date and time as YYYY-MM-DD HH:MM.
String formatDateTime(DateTime value) {
  final time =
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  final date =
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  return '$date $time';
}
