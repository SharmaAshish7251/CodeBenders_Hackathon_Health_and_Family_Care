import 'package:sqflite/sqflite.dart';

import '../models/enum_names.dart';
import '../models/family_member.dart';
import 'database.dart';

/// Every write the repositories perform. Each one is checked against [canWrite].
enum WriteAction {
  manageFamily,
  manageMembers,
  createRecord,
  updateRecord,
  deleteRecord,
  createTask,
  updateTask,
  completeTask,
  deleteTask,
  createMedicine,
  updateMedicine,
  deleteMedicine,
  updateEmergencyInfo,
  updateConsent,
}

/// Thrown when a write is not allowed for the acting member.
class RoleDeniedException implements Exception {
  const RoleDeniedException(this.action, this.message);

  final WriteAction action;
  final String message;

  @override
  String toString() => 'RoleDeniedException($action): $message';
}

/// Thrown when a row to update or delete does not exist in the family.
class NotFoundException implements Exception {
  const NotFoundException(this.entity, this.id);

  final String entity;
  final String id;

  @override
  String toString() => 'NotFoundException($entity: $id)';
}

/// Thrown when the acting user is not a member of the family space.
class NotAMemberException implements Exception {
  const NotAMemberException(this.familyId, this.userId);

  final String familyId;
  final String userId;

  @override
  String toString() => 'NotAMemberException(family: $familyId, user: $userId)';
}

/// Whether a member with [role] may perform [action] (PRD F2).
///
/// - Admin: everything.
/// - Caregiver: care data and tasks, but not family or member management.
/// - Viewer: nothing, except updating their own consent choices.
/// - Delegate: only task updates and completions, and only for tasks assigned
///   to them (see [canCompleteTask] for the assignee check).
bool canWrite(Role role, WriteAction action) {
  if (action == WriteAction.updateConsent) return true;
  switch (role) {
    case Role.admin:
      return true;
    case Role.caregiver:
      return action != WriteAction.manageFamily &&
          action != WriteAction.manageMembers;
    case Role.viewer:
      return false;
    case Role.delegate:
      return action == WriteAction.updateTask ||
          action == WriteAction.completeTask;
  }
}

/// Whether [userId] may complete (or otherwise change) a task assigned to
/// [taskAssigneeId]. Delegates may only touch tasks assigned to themselves.
bool canCompleteTask(Role role, String taskAssigneeId, String userId) {
  switch (role) {
    case Role.admin:
    case Role.caregiver:
      return true;
    case Role.viewer:
      return false;
    case Role.delegate:
      return taskAssigneeId == userId;
  }
}

/// Reads the acting user's role from the members table. Repositories call
/// this instead of trusting a role passed in from the UI.
Future<Role> loadRole(
  DatabaseExecutor db, {
  required String familyId,
  required String userId,
}) async {
  final rows = await db.query(
    DbTables.members,
    columns: ['role'],
    where: 'family_id = ? AND id = ?',
    whereArgs: [familyId, userId],
    limit: 1,
  );
  if (rows.isEmpty) throw NotAMemberException(familyId, userId);
  final role = enumFromName(Role.values, rows.first['role'] as String?);
  // Unknown stored roles fall back to the least-privileged role.
  return role ?? Role.viewer;
}

/// Throws [RoleDeniedException] when [role] may not perform [action].
void ensureCanWrite(Role role, WriteAction action) {
  if (!canWrite(role, action)) {
    throw RoleDeniedException(action, 'Role $role may not $action');
  }
}
