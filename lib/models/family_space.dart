import 'package:flutter/foundation.dart';

/// A family space that holds the care data for one care recipient (PRD F1).
@immutable
class FamilySpace {
  const FamilySpace({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdById,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String inviteCode;
  final String createdById;
  final DateTime createdAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'invite_code': inviteCode,
      'created_by_id': createdById,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Returns null when required fields are missing or malformed.
  static FamilySpace? tryFromMap(Map<String, Object?> map) {
    final id = map['id'];
    final name = map['name'];
    final inviteCode = map['invite_code'];
    final createdById = map['created_by_id'];
    final createdAt = map['created_at'];
    if (id is! String || name is! String || inviteCode is! String) return null;
    if (createdById is! String || createdAt is! int) return null;
    return FamilySpace(
      id: id,
      name: name,
      inviteCode: inviteCode,
      createdById: createdById,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    );
  }
}
