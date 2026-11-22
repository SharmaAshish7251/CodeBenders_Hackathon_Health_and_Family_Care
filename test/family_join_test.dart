import 'package:flutter_test/flutter_test.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:health_and_saftey_care/data/database.dart';
import 'package:health_and_saftey_care/data/role_guard.dart';
import 'package:health_and_saftey_care/models/family_member.dart';
import 'package:health_and_saftey_care/models/family_space.dart';
import 'package:health_and_saftey_care/repositories/activity_repository.dart';
import 'package:health_and_saftey_care/repositories/family_repository.dart';

const _familyId = 'family-1';
const _inviteCode = 'JOIN42';
const _userId = 'user-new';

/// Opens an in-memory database holding the families, members and activity
/// tables. The DDL is copied from migration 0 in database.dart, because the
/// migrations and openCareDatabase() are private or use a real file path.
Future<Database> _openTestDatabase() {
  return openDatabase(
    inMemoryDatabasePath,
    version: 1,
    onCreate: (db, _) async {
      await db.execute(
        'CREATE TABLE ${DbTables.families} ('
        'id TEXT PRIMARY KEY NOT NULL, '
        'name TEXT NOT NULL, '
        'invite_code TEXT NOT NULL, '
        'created_by_id TEXT NOT NULL, '
        'created_at INTEGER NOT NULL)',
      );
      await db.execute(
        'CREATE TABLE ${DbTables.members} ('
        'id TEXT PRIMARY KEY NOT NULL, '
        'family_id TEXT NOT NULL, '
        'name TEXT NOT NULL, '
        'phone TEXT, '
        'role TEXT NOT NULL)',
      );
      await db.execute(
        'CREATE TABLE ${DbTables.activity} ('
        'id TEXT PRIMARY KEY NOT NULL, '
        'family_id TEXT NOT NULL, '
        'actor_id TEXT NOT NULL, '
        'action TEXT NOT NULL, '
        'target_ref TEXT NOT NULL, '
        'at INTEGER NOT NULL)',
      );
    },
  );
}

/// Inserts one family with a known invite code so the test can use it.
Future<void> _seedFamily(Database db) async {
  final family = FamilySpace(
    id: _familyId,
    name: 'Test Family',
    inviteCode: _inviteCode,
    createdById: 'admin-1',
    createdAt: DateTime(2024, 1, 1),
  );
  await db.insert(DbTables.families, family.toMap());
}

void main() {
  late Database db;
  late FamilyRepository repo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await _openTestDatabase();
    await _seedFamily(db);
    repo = SqfliteFamilyRepository(Future.value(db));
  });

  tearDown(() async {
    await db.close();
  });

  test('a valid invite code adds the user as a Viewer', () async {
    final family = await repo.joinByCode(
      code: _inviteCode,
      userId: _userId,
      userName: 'New Member',
      userPhone: '+10000000001',
    );

    expect(family.id, _familyId);
    final members = await repo.members(_familyId);
    final joined = members.singleWhere((m) => m.id == _userId);
    expect(joined.role, Role.viewer);
  });

  test('an unknown invite code throws NotFoundException', () async {
    await expectLater(
      repo.joinByCode(
        code: 'NOPE99',
        userId: _userId,
        userName: 'New Member',
        userPhone: '+10000000001',
      ),
      throwsA(isA<NotFoundException>()),
    );
    expect(await repo.members(_familyId), isEmpty);
  });

  test('a join writes a memberJoined activity event', () async {
    await repo.joinByCode(
      code: _inviteCode,
      userId: _userId,
      userName: 'New Member',
      userPhone: '+10000000001',
    );

    final events = await SqfliteActivityRepository(Future.value(db))
        .recent(_familyId);
    final joins = events
        .where((e) => e.action == ActivityActions.memberJoined)
        .toList();
    expect(joins, hasLength(1));
    expect(joins.single.actorId, _userId);
    expect(joins.single.targetRef, 'member:$_userId');
  });
}
