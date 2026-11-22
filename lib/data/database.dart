import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'demo_data_seeder.dart';

final _random = Random.secure();

/// Generates a unique id for a new row. Time-ordered prefix plus random suffix.
String newEntityId() {
  final suffix = _random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
  return '${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}-$suffix';
}

/// Table names. Code constants only: never built from user input.
class DbTables {
  const DbTables._();

  static const families = 'families';
  static const members = 'members';
  static const records = 'records';
  static const tasks = 'tasks';
  static const activity = 'activity';
  static const consent = 'consent';
  static const medicines = 'medicines';
  static const emergencyInfo = 'emergency_info';
  static const analyticsEvents = 'analytics_events';
}

const _databaseFileName = 'family_care_hub.db';

/// Current schema version. Every schema change adds a numbered migration.
const databaseVersion = 5;

/// Numbered migrations. Index N moves the schema from version N to N + 1.
const List<List<String>> _migrations = [
  [
    'CREATE TABLE ${DbTables.families} ('
        'id TEXT PRIMARY KEY NOT NULL, '
        'name TEXT NOT NULL, '
        'invite_code TEXT NOT NULL, '
        'created_by_id TEXT NOT NULL, '
        'created_at INTEGER NOT NULL)',
    'CREATE TABLE ${DbTables.members} ('
        'id TEXT PRIMARY KEY NOT NULL, '
        'family_id TEXT NOT NULL, '
        'name TEXT NOT NULL, '
        'phone TEXT, '
        'role TEXT NOT NULL)',
    'CREATE TABLE ${DbTables.records} ('
        'id TEXT PRIMARY KEY NOT NULL, '
        'family_id TEXT NOT NULL, '
        'title TEXT NOT NULL, '
        'date INTEGER NOT NULL, '
        'type TEXT NOT NULL, '
        'tags TEXT NOT NULL, '
        'visibility TEXT NOT NULL, '
        'uploader_id TEXT NOT NULL)',
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
    'CREATE TABLE ${DbTables.activity} ('
        'id TEXT PRIMARY KEY NOT NULL, '
        'family_id TEXT NOT NULL, '
        'actor_id TEXT NOT NULL, '
        'action TEXT NOT NULL, '
        'target_ref TEXT NOT NULL, '
        'at INTEGER NOT NULL)',
    'CREATE TABLE ${DbTables.consent} ('
        'user_id TEXT NOT NULL, '
        'purpose TEXT NOT NULL, '
        'granted INTEGER NOT NULL, '
        'updated_at INTEGER NOT NULL, '
        'PRIMARY KEY (user_id, purpose))',
  ],
  [
    'CREATE TABLE ${DbTables.medicines} ('
        'id TEXT PRIMARY KEY NOT NULL, '
        'family_id TEXT NOT NULL, '
        'name TEXT NOT NULL, '
        'schedule_note TEXT, '
        'quantity_on_hand INTEGER NOT NULL, '
        'daily_usage INTEGER NOT NULL, '
        'refill_threshold_days INTEGER NOT NULL)',
  ],
  [
    'CREATE TABLE ${DbTables.emergencyInfo} ('
        'family_id TEXT PRIMARY KEY NOT NULL, '
        'blood_group TEXT, '
        'allergies TEXT, '
        'conditions TEXT, '
        'emergency_contact_name TEXT, '
        'emergency_contact_phone TEXT, '
        'hospital TEXT, '
        'doctor_contact TEXT)',
  ],
  [
    'CREATE TABLE ${DbTables.analyticsEvents} ('
        'id TEXT PRIMARY KEY NOT NULL, '
        'name TEXT NOT NULL, '
        'at TEXT NOT NULL)',
  ],
  [
    'ALTER TABLE ${DbTables.records} ADD COLUMN attachment_path TEXT',
    'ALTER TABLE ${DbTables.records} ADD COLUMN ocr_text TEXT',
  ],
];

/// Opens the local SQLite database in the app's private storage and applies
/// any pending numbered migrations.
Future<Database> openCareDatabase() async {
  final directory = await getApplicationDocumentsDirectory();
  final path = p.join(directory.path, _databaseFileName);
  final db = await openDatabase(
    path,
    version: databaseVersion,
    onCreate: (db, version) async {
      await _runMigrations(db, 0, version);
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      await _runMigrations(db, oldVersion, newVersion);
    },
  );

  // Auto-seed demo data if database is fresh (0 families)
  try {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DbTables.families}'),
    ) ?? 0;
    if (count == 0) {
      await DemoDataSeeder.seedDirect(db);
    }
  } catch (_) {
    // Graceful fallback if tables are in migration
  }

  return db;
}

Future<void> _runMigrations(Database db, int from, int to) async {
  for (var step = from; step < to; step++) {
    final statements = _migrations[step];
    for (final sql in statements) {
      await db.execute(sql);
    }
  }
}
