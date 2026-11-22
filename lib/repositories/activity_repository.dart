import 'package:sqflite/sqflite.dart';

import '../data/database.dart';
import '../models/activity_event.dart';

/// Action names written to the activity log. Code constants only.
class ActivityActions {
  const ActivityActions._();

  static const familyCreated = 'family_created';
  static const memberRoleChanged = 'member_role_changed';
  static const memberRemoved = 'member_removed';
  static const memberJoined = 'member_joined';
  static const recordCreated = 'record_created';
  static const recordUpdated = 'record_updated';
  static const recordDeleted = 'record_deleted';
  static const taskCreated = 'task_created';
  static const taskUpdated = 'task_updated';
  static const taskCompleted = 'task_completed';
  static const taskDeleted = 'task_deleted';
  static const medicineAdded = 'medicine_added';
  static const medicineStockUpdated = 'medicine_stock_updated';
  static const medicineRemoved = 'medicine_removed';
  static const emergencyInfoSaved = 'emergency_info_saved';
}

abstract class ActivityRepository {
  /// Most recent events for a family, newest first.
  Future<List<ActivityEvent>> recent(String familyId, {int limit = 20});
}

class SqfliteActivityRepository implements ActivityRepository {
  const SqfliteActivityRepository(this._database);

  final Future<Database> _database;

  @override
  Future<List<ActivityEvent>> recent(String familyId, {int limit = 20}) async {
    final db = await _database;
    final rows = await db.query(
      DbTables.activity,
      where: 'family_id = ?',
      whereArgs: [familyId],
      orderBy: 'at DESC',
      limit: limit,
    );
    return rows
        .map(ActivityEvent.tryFromMap)
        .whereType<ActivityEvent>()
        .toList();
  }
}

/// Writes one activity row. Other repositories call this inside their own
/// transaction so the event and the change commit (or fail) together.
Future<void> insertActivityEvent(
  DatabaseExecutor executor, {
  required String id,
  required String familyId,
  required String actorId,
  required String action,
  required String targetRef,
  required DateTime at,
}) async {
  final event = ActivityEvent(
    id: id,
    familyId: familyId,
    actorId: actorId,
    action: action,
    targetRef: targetRef,
    at: at,
  );
  await executor.insert(DbTables.activity, event.toMap());
}
