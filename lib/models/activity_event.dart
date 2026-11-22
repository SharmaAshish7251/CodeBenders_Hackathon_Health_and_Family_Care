import 'package:flutter/foundation.dart';

/// One entry in the who-did-what log (PRD F7, F20). Holds no health content,
/// names or phone numbers: only ids, an action name and a target reference.
@immutable
class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.familyId,
    required this.actorId,
    required this.action,
    required this.targetRef,
    required this.at,
  });

  final String id;
  final String familyId;
  final String actorId;
  final String action;
  final String targetRef;
  final DateTime at;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'family_id': familyId,
      'actor_id': actorId,
      'action': action,
      'target_ref': targetRef,
      'at': at.millisecondsSinceEpoch,
    };
  }

  /// Returns null when required fields are missing or malformed.
  static ActivityEvent? tryFromMap(Map<String, Object?> map) {
    final id = map['id'];
    final familyId = map['family_id'];
    final actorId = map['actor_id'];
    final action = map['action'];
    final targetRef = map['target_ref'];
    final at = map['at'];
    if (id is! String || familyId is! String || actorId is! String) return null;
    if (action is! String || targetRef is! String || at is! int) return null;
    return ActivityEvent(
      id: id,
      familyId: familyId,
      actorId: actorId,
      action: action,
      targetRef: targetRef,
      at: DateTime.fromMillisecondsSinceEpoch(at),
    );
  }
}
