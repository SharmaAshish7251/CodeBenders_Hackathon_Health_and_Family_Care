import 'package:sqflite/sqflite.dart';

import '../data/database.dart';
import '../data/role_guard.dart';
import '../models/family_member.dart';
import '../models/record.dart';
import 'activity_repository.dart';

abstract class RecordRepository {
  /// Records visible to [actorId]. Viewers never receive "caregivers only"
  /// records.
  Future<List<CareRecord>> list({
    required String familyId,
    required String actorId,
  });

  Future<void> create({required String actorId, required CareRecord record});

  Future<void> update({required String actorId, required CareRecord record});

  Future<void> delete({
    required String familyId,
    required String actorId,
    required String recordId,
  });
}

class SqfliteRecordRepository implements RecordRepository {
  const SqfliteRecordRepository(this._database);

  final Future<Database> _database;

  @override
  Future<List<CareRecord>> list({
    required String familyId,
    required String actorId,
  }) async {
    final db = await _database;
    final role = await loadRole(db, familyId: familyId, userId: actorId);
    final rows = await db.query(
      DbTables.records,
      where: 'family_id = ?',
      whereArgs: [familyId],
      orderBy: 'date DESC',
    );
    final records = rows
        .map(CareRecord.tryFromMap)
        .whereType<CareRecord>()
        .toList();
    if (role != Role.viewer) return records;
    return records
        .where((record) => record.visibility != RecordVisibility.caregiversOnly)
        .toList();
  }

  @override
  Future<void> create({
    required String actorId,
    required CareRecord record,
  }) async {
    final db = await _database;
    await db.transaction((txn) async {
      final role = await loadRole(
        txn,
        familyId: record.familyId,
        userId: actorId,
      );
      ensureCanWrite(role, WriteAction.createRecord);
      if (record.uploaderId != actorId) {
        throw const RoleDeniedException(
          WriteAction.createRecord,
          'Records must be uploaded by the signed-in user',
        );
      }
      await txn.insert(DbTables.records, record.toMap());
      await insertActivityEvent(
        txn,
        id: newEntityId(),
        familyId: record.familyId,
        actorId: actorId,
        action: ActivityActions.recordCreated,
        targetRef: 'record:${record.id}',
        at: DateTime.now(),
      );
    });
  }

  @override
  Future<void> update({
    required String actorId,
    required CareRecord record,
  }) async {
    final db = await _database;
    await db.transaction((txn) async {
      final role = await loadRole(
        txn,
        familyId: record.familyId,
        userId: actorId,
      );
      ensureCanWrite(role, WriteAction.updateRecord);
      final count = await txn.update(
        DbTables.records,
        record.toMap(),
        where: 'id = ? AND family_id = ?',
        whereArgs: [record.id, record.familyId],
      );
      if (count == 0) throw NotFoundException('record', record.id);
      await insertActivityEvent(
        txn,
        id: newEntityId(),
        familyId: record.familyId,
        actorId: actorId,
        action: ActivityActions.recordUpdated,
        targetRef: 'record:${record.id}',
        at: DateTime.now(),
      );
    });
  }

  @override
  Future<void> delete({
    required String familyId,
    required String actorId,
    required String recordId,
  }) async {
    final db = await _database;
    await db.transaction((txn) async {
      final role = await loadRole(txn, familyId: familyId, userId: actorId);
      ensureCanWrite(role, WriteAction.deleteRecord);
      final count = await txn.delete(
        DbTables.records,
        where: 'id = ? AND family_id = ?',
        whereArgs: [recordId, familyId],
      );
      if (count == 0) throw NotFoundException('record', recordId);
      await insertActivityEvent(
        txn,
        id: newEntityId(),
        familyId: familyId,
        actorId: actorId,
        action: ActivityActions.recordDeleted,
        targetRef: 'record:$recordId',
        at: DateTime.now(),
      );
    });
  }
}
