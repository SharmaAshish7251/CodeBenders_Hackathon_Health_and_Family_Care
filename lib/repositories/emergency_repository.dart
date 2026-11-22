import 'package:sqflite/sqflite.dart';

import '../data/database.dart';
import '../data/role_guard.dart';
import '../models/emergency_info.dart';
import 'activity_repository.dart';

abstract class EmergencyRepository {
  /// The emergency details for a family, or null when none are saved yet.
  Future<EmergencyInfo?> get(String familyId);

  /// Saves the family's emergency details, replacing any earlier version.
  /// Only admins and caregivers may save.
  Future<void> save({required String actorId, required EmergencyInfo info});
}

class SqfliteEmergencyRepository implements EmergencyRepository {
  const SqfliteEmergencyRepository(this._database);

  final Future<Database> _database;

  @override
  Future<EmergencyInfo?> get(String familyId) async {
    final db = await _database;
    final rows = await db.query(
      DbTables.emergencyInfo,
      where: 'family_id = ?',
      whereArgs: [familyId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return EmergencyInfo.tryFromMap(rows.first);
  }

  @override
  Future<void> save({
    required String actorId,
    required EmergencyInfo info,
  }) async {
    final db = await _database;
    await db.transaction((txn) async {
      final role = await loadRole(
        txn,
        familyId: info.familyId,
        userId: actorId,
      );
      ensureCanWrite(role, WriteAction.updateEmergencyInfo);
      await txn.insert(
        DbTables.emergencyInfo,
        info.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await insertActivityEvent(
        txn,
        id: newEntityId(),
        familyId: info.familyId,
        actorId: actorId,
        action: ActivityActions.emergencyInfoSaved,
        targetRef: 'emergency:${info.familyId}',
        at: DateTime.now(),
      );
    });
  }
}
