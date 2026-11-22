import 'package:flutter/foundation.dart';

import 'enum_names.dart';

/// Task status (PRD F5: To do, Done, Skipped).
enum TaskStatus { todo, done, skipped }

/// Task recurrence (PRD F5). A completed recurring task spawns the next one.
enum Recurrence { none, daily, weekly, monthly }

/// A care task assigned to one family member.
@immutable
class CareTask {
  const CareTask({
    required this.id,
    required this.familyId,
    required this.title,
    required this.dueAt,
    required this.assigneeId,
    required this.status,
    required this.recurrence,
    this.description,
    this.completedById,
    this.completedAt,
  });

  final String id;
  final String familyId;
  final String title;
  final String? description;
  final DateTime dueAt;
  final String assigneeId;
  final TaskStatus status;
  final Recurrence recurrence;
  final String? completedById;
  final DateTime? completedAt;

  CareTask copyWith({
    String? title,
    String? description,
    DateTime? dueAt,
    String? assigneeId,
    TaskStatus? status,
    Recurrence? recurrence,
    String? completedById,
    DateTime? completedAt,
  }) {
    return CareTask(
      id: id,
      familyId: familyId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueAt: dueAt ?? this.dueAt,
      assigneeId: assigneeId ?? this.assigneeId,
      status: status ?? this.status,
      recurrence: recurrence ?? this.recurrence,
      completedById: completedById ?? this.completedById,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'family_id': familyId,
      'title': title,
      'description': description,
      'due_at': dueAt.millisecondsSinceEpoch,
      'assignee_id': assigneeId,
      'status': status.name,
      'recurrence': recurrence.name,
      'completed_by_id': completedById,
      'completed_at': completedAt?.millisecondsSinceEpoch,
    };
  }

  /// Returns null when required fields are missing or malformed.
  static CareTask? tryFromMap(Map<String, Object?> map) {
    final id = map['id'];
    final familyId = map['family_id'];
    final title = map['title'];
    final dueAt = map['due_at'];
    final assigneeId = map['assignee_id'];
    final status = enumFromName(TaskStatus.values, map['status'] as String?);
    final recurrence = enumFromName(
      Recurrence.values,
      map['recurrence'] as String?,
    );
    if (id is! String || familyId is! String || title is! String) return null;
    if (dueAt is! int || assigneeId is! String) return null;
    if (status == null || recurrence == null) return null;

    final description = map['description'];
    final completedById = map['completed_by_id'];
    final completedAt = map['completed_at'];
    return CareTask(
      id: id,
      familyId: familyId,
      title: title,
      description: description is String ? description : null,
      dueAt: DateTime.fromMillisecondsSinceEpoch(dueAt),
      assigneeId: assigneeId,
      status: status,
      recurrence: recurrence,
      completedById: completedById is String ? completedById : null,
      completedAt: completedAt is int
          ? DateTime.fromMillisecondsSinceEpoch(completedAt)
          : null,
    );
  }
}
