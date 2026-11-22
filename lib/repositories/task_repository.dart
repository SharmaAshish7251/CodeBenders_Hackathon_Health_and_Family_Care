import 'package:sqflite/sqflite.dart';

import '../data/database.dart';
import '../data/role_guard.dart';
import '../models/family_member.dart';
import '../models/task.dart';
import 'activity_repository.dart';

abstract class TaskRepository {
  Future<List<CareTask>> list({
    required String familyId,
    required String actorId,
  });

  Future<void> create({required String actorId, required CareTask task});

  /// Saves the given task fields (title, due date, assignee, skip, and so on).
  /// Use [complete] to mark a task done, so that completion is recorded.
  Future<void> update({required String actorId, required CareTask task});

  /// Marks a task done, records who completed it and when, and creates the
  /// next occurrence when the task recurs.
  Future<void> complete({
    required String familyId,
    required String actorId,
    required String taskId,
  });

  Future<void> delete({
    required String familyId,
    required String actorId,
    required String taskId,
  });
}

/// Next due time for a recurring task. Monthly uses calendar months.
DateTime nextDueAt(DateTime dueAt, Recurrence recurrence) {
  switch (recurrence) {
    case Recurrence.none:
      return dueAt;
    case Recurrence.daily:
      return DateTime(dueAt.year, dueAt.month, dueAt.day + 1, dueAt.hour, dueAt.minute);
    case Recurrence.weekly:
      return DateTime(dueAt.year, dueAt.month, dueAt.day + 7, dueAt.hour, dueAt.minute);
    case Recurrence.monthly:
      return DateTime(dueAt.year, dueAt.month + 1, dueAt.day, dueAt.hour, dueAt.minute);
  }
}

class SqfliteTaskRepository implements TaskRepository {
  const SqfliteTaskRepository(this._database);

  final Future<Database> _database;

  @override
  Future<List<CareTask>> list({
    required String familyId,
    required String actorId,
  }) async {
    final db = await _database;
    await loadRole(db, familyId: familyId, userId: actorId);
    final rows = await db.query(
      DbTables.tasks,
      where: 'family_id = ?',
      whereArgs: [familyId],
      orderBy: 'due_at ASC',
    );
    return rows.map(CareTask.tryFromMap).whereType<CareTask>().toList();
  }

  @override
  Future<void> create({
    required String actorId,
    required CareTask task,
  }) async {
    final db = await _database;
    await db.transaction((txn) async {
      final role = await loadRole(
        txn,
        familyId: task.familyId,
        userId: actorId,
      );
      ensureCanWrite(role, WriteAction.createTask);
      await txn.insert(DbTables.tasks, task.toMap());
      await insertActivityEvent(
        txn,
        id: newEntityId(),
        familyId: task.familyId,
        actorId: actorId,
        action: ActivityActions.taskCreated,
        targetRef: 'task:${task.id}',
        at: DateTime.now(),
      );
    });
  }

  @override
  Future<void> update({
    required String actorId,
    required CareTask task,
  }) async {
    final db = await _database;
    await db.transaction((txn) async {
      final role = await loadRole(
        txn,
        familyId: task.familyId,
        userId: actorId,
      );
      ensureCanWrite(role, WriteAction.updateTask);
      final existing = await _task(txn, task.familyId, task.id);
      if (!canCompleteTask(role, existing.assigneeId, actorId)) {
        throw const RoleDeniedException(
          WriteAction.updateTask,
          'Delegates may only change tasks assigned to them',
        );
      }
      // Delegates cannot hand their tasks to someone else.
      if (role == Role.delegate && task.assigneeId != existing.assigneeId) {
        throw const RoleDeniedException(
          WriteAction.updateTask,
          'Delegates cannot reassign tasks',
        );
      }
      await txn.update(
        DbTables.tasks,
        task.toMap(),
        where: 'id = ? AND family_id = ?',
        whereArgs: [task.id, task.familyId],
      );
      await insertActivityEvent(
        txn,
        id: newEntityId(),
        familyId: task.familyId,
        actorId: actorId,
        action: ActivityActions.taskUpdated,
        targetRef: 'task:${task.id}',
        at: DateTime.now(),
      );
    });
  }

  @override
  Future<void> complete({
    required String familyId,
    required String actorId,
    required String taskId,
  }) async {
    final db = await _database;
    await db.transaction((txn) async {
      final role = await loadRole(txn, familyId: familyId, userId: actorId);
      ensureCanWrite(role, WriteAction.completeTask);
      final existing = await _task(txn, familyId, taskId);
      if (!canCompleteTask(role, existing.assigneeId, actorId)) {
        throw const RoleDeniedException(
          WriteAction.completeTask,
          'Delegates may only complete tasks assigned to them',
        );
      }
      if (existing.status == TaskStatus.done) return;

      final now = DateTime.now();
      final done = existing.copyWith(
        status: TaskStatus.done,
        completedById: actorId,
        completedAt: now,
      );
      await txn.update(
        DbTables.tasks,
        done.toMap(),
        where: 'id = ? AND family_id = ?',
        whereArgs: [taskId, familyId],
      );

      if (existing.recurrence != Recurrence.none) {
        final next = CareTask(
          id: newEntityId(),
          familyId: familyId,
          title: existing.title,
          description: existing.description,
          dueAt: nextDueAt(existing.dueAt, existing.recurrence),
          assigneeId: existing.assigneeId,
          status: TaskStatus.todo,
          recurrence: existing.recurrence,
        );
        await txn.insert(DbTables.tasks, next.toMap());
      }

      await insertActivityEvent(
        txn,
        id: newEntityId(),
        familyId: familyId,
        actorId: actorId,
        action: ActivityActions.taskCompleted,
        targetRef: 'task:$taskId',
        at: now,
      );
    });
  }

  @override
  Future<void> delete({
    required String familyId,
    required String actorId,
    required String taskId,
  }) async {
    final db = await _database;
    await db.transaction((txn) async {
      final role = await loadRole(txn, familyId: familyId, userId: actorId);
      ensureCanWrite(role, WriteAction.deleteTask);
      final count = await txn.delete(
        DbTables.tasks,
        where: 'id = ? AND family_id = ?',
        whereArgs: [taskId, familyId],
      );
      if (count == 0) throw NotFoundException('task', taskId);
      await insertActivityEvent(
        txn,
        id: newEntityId(),
        familyId: familyId,
        actorId: actorId,
        action: ActivityActions.taskDeleted,
        targetRef: 'task:$taskId',
        at: DateTime.now(),
      );
    });
  }

  Future<CareTask> _task(
    DatabaseExecutor executor,
    String familyId,
    String taskId,
  ) async {
    final rows = await executor.query(
      DbTables.tasks,
      where: 'id = ? AND family_id = ?',
      whereArgs: [taskId, familyId],
      limit: 1,
    );
    if (rows.isEmpty) throw NotFoundException('task', taskId);
    final task = CareTask.tryFromMap(rows.first);
    if (task == null) throw NotFoundException('task', taskId);
    return task;
  }
}
