import 'package:flutter/foundation.dart';

import 'enum_names.dart';

/// Access roles inside a family space (PRD F2).
enum Role { admin, caregiver, viewer, delegate }

/// A person who belongs to a family space.
@immutable
class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.familyId,
    required this.name,
    required this.role,
    this.phone,
  });

  final String id;
  final String familyId;
  final String name;
  final String? phone;
  final Role role;

  FamilyMember copyWith({Role? role}) {
    return FamilyMember(
      id: id,
      familyId: familyId,
      name: name,
      phone: phone,
      role: role ?? this.role,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'family_id': familyId,
      'name': name,
      'phone': phone,
      'role': role.name,
    };
  }

  /// Returns null when required fields are missing or malformed.
  static FamilyMember? tryFromMap(Map<String, Object?> map) {
    final id = map['id'];
    final familyId = map['family_id'];
    final name = map['name'];
    final phone = map['phone'];
    final role = enumFromName(Role.values, map['role'] as String?);
    if (id is! String || familyId is! String || name is! String) return null;
    if (role == null) return null;
    return FamilyMember(
      id: id,
      familyId: familyId,
      name: name,
      phone: phone is String ? phone : null,
      role: role,
    );
  }
}
