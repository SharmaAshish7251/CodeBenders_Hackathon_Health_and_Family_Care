import 'package:flutter_test/flutter_test.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:health_and_saftey_care/data/database.dart';
import 'package:health_and_saftey_care/data/role_guard.dart';
import 'package:health_and_saftey_care/models/family_member.dart';
import 'package:health_and_saftey_care/models/record.dart';
import 'package:health_and_saftey_care/models/task.dart';
import 'package:health_and_saftey_care/repositories/activity_repository.dart';
import 'package:health_and_saftey_care/repositories/record_repository.dart';
import 'package:health_and_saftey_care/repositories/task_repository.dart';

const _familyId = 'family-1';
const _viewerId = 'viewer-1';
const _caregiverId = 'caregiver-1';

/// Opens an in-memory database holding the members, records, tasks and
/// activity tables. The DDL is copied from migration 0 in database.dart,
/// because the migrations and openCareDatabase() are private or use a real
/// file path.
Future<Database> _openTestDatabase() {
  return openDatabase(
    inMemoryDatabasePath,
    version: 1,
    onCreate: (db, _) async {
      await db.execute(
        'CREATE TABLE ${DbTables.members} ('
        'id TEXT PRIMARY KEY NOT NULL, '
        'family_id TEXT NOT NULL, '
        'name TEXT NOT NULL, '
        'phone TEXT, '
        'role TEXT NOT NULL)',
      );
      await db.execute(
        'CREATE TABLE ${DbTables.records} ('
        'id TEXT PRIMARY KEY NOT NULL, '
        'family_id TEXT NOT NULL, '
        'title TEXT NOT NULL, '
        'date INTEGER NOT NULL, '
        'type TEXT NOT NULL, '
        'tags TEXT NOT NULL, '
        'visibility TEXT NOT NULL, '
        'uploader_id TEXT NOT NULL, '
        'attachment_path TEXT, '
        'ocr_text TEXT)',
      );
      await db.execute(
        'CREATE TABLE ${DbTables.tasks} ('
        'id TEXT PRIMARY KEY NOT NULL, '
        'family_id TEXT NOT NULL, '
        'title TEXT NOT NULL, '
        'description TEXT, '
        'due_at INTEGER NOT NULL, '
        'assignee_id TEXT NOT NULL, '
        'status TEXT NOT NULL, '
        'recurrence TEXT NOT NULL, '
        'completed_by_id TEXT, '
        'completed_at INTEGER)',
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

/// Inserts one member with the given role into the test family.
Future<void> _seedMember(Database db, String id, Role role) async {
  final member = FamilyMember(
    id: id,
    familyId: _familyId,
    name: 'Member $id',
    role: role,
  );
  await db.insert(DbTables.members, member.toMap());
}

CareRecord _record({required String id, required String uploaderId}) {
  return CareRecord(
    id: id,
    familyId: _familyId,
    title: 'Blood test',
    date: DateTime(2024, 1, 1),
    type: 'lab',
    tags: const ['blood'],
    visibility: RecordVisibility.family,
    uploaderId: uploaderId,
  );
}

CareTask _task({required String id, required String assigneeId}) {
  return CareTask(
    id: id,
    familyId: _familyId,
    title: 'Give medicine',
    dueAt: DateTime(2024, 1, 1, 9),
    assigneeId: assigneeId,
    status: TaskStatus.todo,
    recurrence: Recurrence.none,
  );
}

void main() {
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await _openTestDatabase();
    await _seedMember(db, _viewerId, Role.viewer);
    await _seedMember(db, _caregiverId, Role.caregiver);
  });

  tearDown(() async {
    await db.close();
  });

  group('record create', () {
    test('a Viewer is rejected with RoleDeniedException', () async {
      final repo = SqfliteRecordRepository(Future.value(db));

      await expectLater(
        repo.create(
          actorId: _viewerId,
          record: _record(id: 'record-v', uploaderId: _viewerId),
        ),
        throwsA(isA<RoleDeniedException>()),
      );
      expect(await db.query(DbTables.records), isEmpty);
    });

    test('a Caregiver succeeds and writes a recordCreated activity event',
        () async {
      final repo = SqfliteRecordRepository(Future.value(db));

      await repo.create(
        actorId: _caregiverId,
        record: _record(id: 'record-c', uploaderId: _caregiverId),
      );

      expect(await db.query(DbTables.records), hasLength(1));
      final events = await SqfliteActivityRepository(Future.value(db))
          .recent(_familyId);
      final created = events
          .where((e) => e.action == ActivityActions.recordCreated)
          .toList();
      expect(created, hasLength(1));
      expect(created.single.actorId, _caregiverId);
      expect(created.single.targetRef, 'record:record-c');
    });
  });

  group('task create', () {
    test('a Viewer is rejected with RoleDeniedException', () async {
      final repo = SqfliteTaskRepository(Future.value(db));

      await expectLater(
        repo.create(
          actorId: _viewerId,
          task: _task(id: 'task-v', assigneeId: _viewerId),
        ),
        throwsA(isA<RoleDeniedException>()),
      );
      expect(await db.query(DbTables.tasks), isEmpty);
    });

    test('a Caregiver succeeds and writes a taskCreated activity event',
        () async {
      final repo = SqfliteTaskRepository(Future.value(db));

      await repo.create(
        actorId: _caregiverId,
        task: _task(id: 'task-c', assigneeId: _caregiverId),
      );

      expect(await db.query(DbTables.tasks), hasLength(1));
      final events = await SqfliteActivityRepository(Future.value(db))
          .recent(_familyId);
      final created = events
          .where((e) => e.action == ActivityActions.taskCreated)
          .toList();
      expect(created, hasLength(1));
      expect(created.single.actorId, _caregiverId);
      expect(created.single.targetRef, 'task:task-c');
    });
  });
}
