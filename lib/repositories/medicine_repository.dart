import 'package:sqflite/sqflite.dart';

import '../data/database.dart';
import '../data/role_guard.dart';
import '../models/medicine.dart';
import 'activity_repository.dart';

abstract class MedicineRepository {
  /// Medicines in a family, ordered by name.
  Future<List<Medicine>> list(String familyId);

  Future<void> add({required String actorId, required Medicine medicine});

  /// Sets the stock count for one medicine.
  Future<void> updateStock({
    required String familyId,
    required String actorId,
    required String medicineId,
    required int quantityOnHand,
  });

  Future<void> delete({
    required String familyId,
    required String actorId,
    required String medicineId,
  });
}

class SqfliteMedicineRepository implements MedicineRepository {
  const SqfliteMedicineRepository(this._database);

  final Future<Database> _database;

  @override
  Future<List<Medicine>> list(String familyId) async {
    final db = await _database;
    final rows = await db.query(
      DbTables.medicines,
      where: 'family_id = ?',
      whereArgs: [familyId],
      orderBy: 'name ASC',
    );
    return rows.map(Medicine.tryFromMap).whereType<Medicine>().toList();
  }

  @override
  Future<void> add({
    required String actorId,
    required Medicine medicine,
  }) async {
    final db = await _database;
    await db.transaction((txn) async {
      final role = await loadRole(
        txn,
        familyId: medicine.familyId,
        userId: actorId,
      );
      ensureCanWrite(role, WriteAction.createMedicine);
      await txn.insert(DbTables.medicines, medicine.toMap());
      await insertActivityEvent(
        txn,
        id: newEntityId(),
        familyId: medicine.familyId,
        actorId: actorId,
        action: ActivityActions.medicineAdded,
        targetRef: 'medicine:${medicine.id}',
        at: DateTime.now(),
      );
    });
  }

  @override
  Future<void> updateStock({
    required String familyId,
    required String actorId,
    required String medicineId,
    required int quantityOnHand,
  }) async {
    if (quantityOnHand < 0) {
      throw ArgumentError.value(quantityOnHand, 'quantityOnHand', 'must be 0 or more');
    }
    final db = await _database;
    await db.transaction((txn) async {
      final role = await loadRole(txn, familyId: familyId, userId: actorId);
      ensureCanWrite(role, WriteAction.updateMedicine);
      final count = await txn.update(
        DbTables.medicines,
        {'quantity_on_hand': quantityOnHand},
        where: 'id = ? AND family_id = ?',
        whereArgs: [medicineId, familyId],
      );
      if (count == 0) throw NotFoundException('medicine', medicineId);
      await insertActivityEvent(
        txn,
        id: newEntityId(),
        familyId: familyId,
        actorId: actorId,
        action: ActivityActions.medicineStockUpdated,
        targetRef: 'medicine:$medicineId',
        at: DateTime.now(),
      );
    });
  }

  @override
  Future<void> delete({
    required String familyId,
    required String actorId,
    required String medicineId,
  }) async {
    final db = await _database;
    await db.transaction((txn) async {
      final role = await loadRole(txn, familyId: familyId, userId: actorId);
      ensureCanWrite(role, WriteAction.deleteMedicine);
      final count = await txn.delete(
        DbTables.medicines,
        where: 'id = ? AND family_id = ?',
        whereArgs: [medicineId, familyId],
      );
      if (count == 0) throw NotFoundException('medicine', medicineId);
      await insertActivityEvent(
        txn,
        id: newEntityId(),
        familyId: familyId,
        actorId: actorId,
        action: ActivityActions.medicineRemoved,
        targetRef: 'medicine:$medicineId',
        at: DateTime.now(),
      );
    });
  }
}
