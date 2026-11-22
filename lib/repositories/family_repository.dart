import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../data/database.dart';
import '../data/role_guard.dart';
import '../models/consent.dart';
import '../models/family_member.dart';
import '../models/family_space.dart';
import 'activity_repository.dart';

const _inviteAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
final _inviteRandom = Random.secure();

abstract class FamilyRepository {
  /// The first family space stored on this device, or null if none yet.
  Future<FamilySpace?> currentFamily();

  /// Creates a family space and adds [adminId] as its admin member.
  Future<FamilySpace> createFamily({
    required String name,
    required String adminId,
    required String adminName,
    required String adminPhone,
  });

  /// Adds the user as a Viewer of the family whose invite code is [code].
  /// Throws [NotFoundException] when no family has that code.
  Future<FamilySpace> joinByCode({
    required String code,
    required String userId,
    required String userName,
    required String userPhone,
  });

  Future<List<FamilyMember>> members(String familyId);

  Future<void> changeMemberRole({
    required String familyId,
    required String actorId,
    required String memberId,
    required Role role,
  });

  Future<void> removeMember({
    required String familyId,
    required String actorId,
    required String memberId,
  });

  /// Consent decisions for one user. Purposes with no stored row are false.
  Future<Map<ConsentPurpose, bool>> consents(String userId);

  Future<void> setConsent({
    required String userId,
    required ConsentPurpose purpose,
    required bool granted,
  });
}

class SqfliteFamilyRepository implements FamilyRepository {
  const SqfliteFamilyRepository(this._database);

  final Future<Database> _database;

  @override
  Future<FamilySpace?> currentFamily() async {
    final db = await _database;
    final rows = await db.query(
      DbTables.families,
      orderBy: 'created_at ASC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return FamilySpace.tryFromMap(rows.first);
  }

  @override
  Future<FamilySpace> createFamily({
    required String name,
    required String adminId,
    required String adminName,
    required String adminPhone,
  }) async {
    final db = await _database;
    final now = DateTime.now();
    final family = FamilySpace(
      id: newEntityId(),
      name: name,
      inviteCode: _generateInviteCode(),
      createdById: adminId,
      createdAt: now,
    );
    final admin = FamilyMember(
      id: adminId,
      familyId: family.id,
      name: adminName,
      phone: adminPhone,
      role: Role.admin,
    );
    await db.transaction((txn) async {
      // No existing family yet, so there is no role to check against. The
      // creator becomes admin of the space they are creating.
      ensureCanWrite(Role.admin, WriteAction.manageFamily);
      await txn.insert(DbTables.families, family.toMap());
      await txn.insert(DbTables.members, admin.toMap());
      await insertActivityEvent(
        txn,
        id: newEntityId(),
        familyId: family.id,
        actorId: adminId,
        action: ActivityActions.familyCreated,
        targetRef: 'family:${family.id}',
        at: now,
      );
    });
    return family;
  }

  @override
  Future<FamilySpace> joinByCode({
    required String code,
    required String userId,
    required String userName,
    required String userPhone,
  }) async {
    final db = await _database;
    final inviteCode = code.trim().toUpperCase();
    final now = DateTime.now();
    return db.transaction((txn) async {
      final rows = await txn.query(
        DbTables.families,
        where: 'invite_code = ?',
        whereArgs: [inviteCode],
        limit: 1,
      );
      final family = rows.isEmpty ? null : FamilySpace.tryFromMap(rows.first);
      if (family == null) throw NotFoundException('family', inviteCode);
      // The joiner is not a member yet, so there is no role to check. New
      // members start as Viewer, the least-privileged role.
      final member = FamilyMember(
        id: userId,
        familyId: family.id,
        name: userName,
        phone: userPhone,
        role: Role.viewer,
      );
      await txn.insert(DbTables.members, member.toMap());
      await insertActivityEvent(
        txn,
        id: newEntityId(),
        familyId: family.id,
        actorId: userId,
        action: ActivityActions.memberJoined,
        targetRef: 'member:$userId',
        at: now,
      );
      return family;
    });
  }

  @override
  Future<List<FamilyMember>> members(String familyId) async {
    final db = await _database;
    final rows = await db.query(
      DbTables.members,
      where: 'family_id = ?',
      whereArgs: [familyId],
      orderBy: 'name ASC',
    );
    return rows
        .map(FamilyMember.tryFromMap)
        .whereType<FamilyMember>()
        .toList();
  }

  @override
  Future<void> changeMemberRole({
    required String familyId,
    required String actorId,
    required String memberId,
    required Role role,
  }) async {
    final db = await _database;
    await db.transaction((txn) async {
      final actorRole = await loadRole(
        txn,
        familyId: familyId,
        userId: actorId,
      );
      ensureCanWrite(actorRole, WriteAction.manageMembers);
      final target = await _member(txn, familyId, memberId);
      if (target.role == Role.admin && role != Role.admin) {
        await _ensureAnotherAdmin(txn, familyId, memberId);
      }
      await txn.update(
        DbTables.members,
        {'role': role.name},
        where: 'id = ? AND family_id = ?',
        whereArgs: [memberId, familyId],
      );
      await insertActivityEvent(
        txn,
        id: newEntityId(),
        familyId: familyId,
        actorId: actorId,
        action: ActivityActions.memberRoleChanged,
        targetRef: 'member:$memberId',
        at: DateTime.now(),
      );
    });
  }

  @override
  Future<void> removeMember({
    required String familyId,
    required String actorId,
    required String memberId,
  }) async {
    final db = await _database;
    await db.transaction((txn) async {
      final actorRole = await loadRole(
        txn,
        familyId: familyId,
        userId: actorId,
      );
      ensureCanWrite(actorRole, WriteAction.manageMembers);
      final target = await _member(txn, familyId, memberId);
      if (target.role == Role.admin) {
        await _ensureAnotherAdmin(txn, familyId, memberId);
      }
      await txn.delete(
        DbTables.members,
        where: 'id = ? AND family_id = ?',
        whereArgs: [memberId, familyId],
      );
      await insertActivityEvent(
        txn,
        id: newEntityId(),
        familyId: familyId,
        actorId: actorId,
        action: ActivityActions.memberRemoved,
        targetRef: 'member:$memberId',
        at: DateTime.now(),
      );
    });
  }

  @override
  Future<Map<ConsentPurpose, bool>> consents(String userId) async {
    final db = await _database;
    final rows = await db.query(
      DbTables.consent,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    final result = {for (final purpose in ConsentPurpose.values) purpose: false};
    for (final row in rows) {
      final record = ConsentRecord.tryFromMap(row);
      if (record != null) result[record.purpose] = record.granted;
    }
    return result;
  }

  @override
  Future<void> setConsent({
    required String userId,
    required ConsentPurpose purpose,
    required bool granted,
  }) async {
    final db = await _database;
    // Consent is personal, not family data, and it must be possible to
    // withdraw it before a family exists (onboarding). So the role check is
    // made with a role that canWrite allows for updateConsent.
    ensureCanWrite(Role.viewer, WriteAction.updateConsent);
    final record = ConsentRecord(
      userId: userId,
      purpose: purpose,
      granted: granted,
      updatedAt: DateTime.now(),
    );
    await db.insert(
      DbTables.consent,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<FamilyMember> _member(
    DatabaseExecutor executor,
    String familyId,
    String memberId,
  ) async {
    final rows = await executor.query(
      DbTables.members,
      where: 'id = ? AND family_id = ?',
      whereArgs: [memberId, familyId],
      limit: 1,
    );
    if (rows.isEmpty) throw NotFoundException('member', memberId);
    final member = FamilyMember.tryFromMap(rows.first);
    if (member == null) throw NotFoundException('member', memberId);
    return member;
  }

  /// Stops the last admin from being demoted or removed, which would leave
  /// the family space with nobody able to manage members.
  Future<void> _ensureAnotherAdmin(
    DatabaseExecutor executor,
    String familyId,
    String memberId,
  ) async {
    final rows = await executor.query(
      DbTables.members,
      columns: ['id'],
      where: 'family_id = ? AND role = ? AND id != ?',
      whereArgs: [familyId, Role.admin.name, memberId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw const RoleDeniedException(
        WriteAction.manageMembers,
        'The last admin cannot be demoted or removed',
      );
    }
  }

  String _generateInviteCode() {
    final random = _inviteRandom;
    return [
      for (var i = 0; i < 6; i++)
        _inviteAlphabet[random.nextInt(_inviteAlphabet.length)],
    ].join();
  }
}
