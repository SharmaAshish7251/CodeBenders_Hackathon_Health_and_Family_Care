import 'package:sqflite/sqflite.dart';

import '../data/database.dart';

/// Event names for the local analytics log (PRD F20). Code constants only.
/// Event parameters are never stored: only the name and the time.
class AnalyticsEvents {
  const AnalyticsEvents._();

  static const summaryShared = 'summary_shared';
  static const taskCompleted = 'task_completed';
  static const ocrSaved = 'ocr_saved';
  static const emergencyOpened = 'emergency_opened';
  static const languageChanged = 'language_changed';
  static const themeChanged = 'theme_changed';
}

abstract class AnalyticsRepository {
  /// Records one event by name. Does nothing when the user has opted out.
  Future<void> log(String name);

  /// Number of stored events.
  Future<int> count();
}

class SqfliteAnalyticsRepository implements AnalyticsRepository {
  const SqfliteAnalyticsRepository(this._database, this._isEnabled);

  final Future<Database> _database;

  /// Returns whether analytics is enabled. Checked on every [log] call.
  final Future<bool> Function() _isEnabled;

  @override
  Future<void> log(String name) async {
    if (!await _isEnabled()) return;
    final db = await _database;
    await db.insert(DbTables.analyticsEvents, {
      'id': newEntityId(),
      'name': name,
      'at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<int> count() async {
    final db = await _database;
    final rows = await db.query(
      DbTables.analyticsEvents,
      columns: ['COUNT(*)'],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }
}
