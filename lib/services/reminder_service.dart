import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/task.dart';

/// Local notifications for task reminders (PRD F5). A reminder fires
/// [_reminderOffset] before a task is due. The time is scheduled as an absolute
/// UTC instant, so the device time zone does not matter.
class ReminderService {
  static const _reminderOffset = Duration(minutes: 30);
  static const _channelId = 'task_reminders';
  static const _channelName = 'Task reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Call once at startup, before runApp.
  Future<void> init() async {
    tz.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            importance: Importance.high,
          ),
        );
    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Schedules the reminder for [task], replacing any earlier one with the same
  /// id. [body] is the localized notification text, passed in by the caller.
  Future<void> scheduleTaskReminder(
    CareTask task, {
    required String body,
  }) async {
    final id = _notificationId(task.id);
    final fireAt = task.dueAt.subtract(_reminderOffset);
    if (task.status != TaskStatus.todo || !fireAt.isAfter(DateTime.now())) {
      // Clear any earlier reminder, for example when a task was finished or
      // moved to a time that has already passed.
      await _plugin.cancel(id);
      return;
    }
    await _plugin.zonedSchedule(
      id,
      task.title,
      body,
      tz.TZDateTime.from(fireAt.toUtc(), tz.UTC),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelTaskReminder(String taskId) {
    return _plugin.cancel(_notificationId(taskId));
  }

  static int _notificationId(String taskId) => taskId.hashCode & 0x7fffffff;
}

final reminderService = ReminderService();
