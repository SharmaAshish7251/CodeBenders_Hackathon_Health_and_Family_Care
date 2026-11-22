import '../l10n/app_localizations.dart';
import '../models/activity_event.dart';
import '../models/appointment.dart';
import '../models/medicine.dart';
import '../models/record.dart';
import '../models/task.dart';
import '../widgets/care_labels.dart';

/// Number of calendar days covered by records and activity, today included.
const summaryWindowDays = 7;

/// Most record lines in the summary (keeps the WhatsApp message short).
const summaryMaxRecordLines = 10;

/// Most activity lines in the summary (PRD F8).
const summaryMaxActivityLines = 20;

/// Builds the plain-text care summary for WhatsApp (PRD F8). Pure: it reads
/// only its arguments.
///
/// - Records and activity cover the last [summaryWindowDays] days, today
///   included.
/// - caregiversOnly records are always left out. Attachments are never passed
///   in, so they cannot appear in the text.
String buildCareSummary({
  required AppLocalizations l10n,
  required String recipientName,
  required DateTime now,
  required List<CareTask> tasks,
  required List<CareRecord> records,
  required List<Medicine> medicines,
  required List<ActivityEvent> activity,
  required Map<String, String> memberNames,
  required List<Appointment> appointments,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final windowStart = DateTime(
    today.year,
    today.month,
    today.day - (summaryWindowDays - 1),
  );

  String nameOf(String id) => memberNames[id] ?? l10n.dashboardUnknownMember;

  final sections = <String>[
    '${l10n.summaryRecipientLine(recipientName)}\n'
        '${l10n.summaryPeriodLine(formatDate(windowStart), formatDate(today))}',
  ];

  void addSection(String title, List<String> body) {
    final lines = body.isEmpty ? [l10n.summaryNone] : body;
    sections.add([title, ...lines].join('\n'));
  }

  // Upcoming appointments, soonest first.
  final upcoming = [
    for (final appointment in appointments)
      if (!appointment.dateTime.isBefore(now)) appointment,
  ]..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  addSection(l10n.summarySectionAppointments, [
    for (final appointment in upcoming)
      l10n.summaryAppointmentLine(
        appointment.formattedDateTime,
        appointment.doctorName,
      ),
  ]);

  // Pending (todo) tasks grouped by assignee name. Overdue ones are marked.
  final pending = [
    for (final task in tasks)
      if (task.status == TaskStatus.todo) task,
  ]..sort((a, b) {
      final byName = nameOf(a.assigneeId).compareTo(nameOf(b.assigneeId));
      return byName != 0 ? byName : a.dueAt.compareTo(b.dueAt);
    });
  addSection(l10n.summarySectionTasks, [
    for (final task in pending)
      task.dueAt.isBefore(now)
          ? l10n.summaryTaskOverdueLine(
              nameOf(task.assigneeId),
              task.title,
              formatDateTime(task.dueAt),
            )
          : l10n.summaryTaskLine(
              nameOf(task.assigneeId),
              task.title,
              formatDateTime(task.dueAt),
            ),
  ]);

  // Medicines whose days left are below their refill threshold.
  final lowStock = [
    for (final medicine in medicines)
      if (medicine.daysRemaining != null &&
          medicine.daysRemaining! < medicine.refillThresholdDays)
        medicine,
  ];
  addSection(l10n.summarySectionMedicines, [
    for (final medicine in lowStock)
      l10n.summaryMedicineLine(
        medicine.name,
        l10n.medicineDaysRemaining(medicine.daysRemaining!),
      ),
  ]);

  // Recent records, newest first. caregiversOnly records are excluded.
  final recent = [
    for (final record in records)
      if (record.visibility == RecordVisibility.family &&
          !record.date.isBefore(windowStart))
        record,
  ]..sort((a, b) => b.date.compareTo(a.date));
  addSection(l10n.summarySectionRecords, [
    for (final record in recent.take(summaryMaxRecordLines))
      l10n.summaryRecordLine(formatDate(record.date), record.title),
  ]);

  // Recent activity, newest first, capped at 20 lines.
  final events = [
    for (final event in activity)
      if (!event.at.isBefore(windowStart)) event,
  ]..sort((a, b) => b.at.compareTo(a.at));
  addSection(l10n.summarySectionActivity, [
    for (final event in events.take(summaryMaxActivityLines))
      l10n.summaryActivityLine(
        formatDateTime(event.at),
        activityLabel(l10n, event.action),
        nameOf(event.actorId),
      ),
  ]);

  return sections.join('\n\n');
}
