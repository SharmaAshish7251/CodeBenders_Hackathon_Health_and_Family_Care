import 'package:flutter/foundation.dart';

/// Emergency details for one family (PRD F10). One row per family.
@immutable
class EmergencyInfo {
  const EmergencyInfo({
    required this.familyId,
    this.bloodGroup,
    this.allergies,
    this.conditions,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.hospital,
    this.doctorContact,
  });

  final String familyId;
  final String? bloodGroup;
  final String? allergies;
  final String? conditions;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? hospital;
  final String? doctorContact;

  Map<String, Object?> toMap() {
    return {
      'family_id': familyId,
      'blood_group': bloodGroup,
      'allergies': allergies,
      'conditions': conditions,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'hospital': hospital,
      'doctor_contact': doctorContact,
    };
  }

  /// Returns null when the family id is missing or malformed.
  /// Optional text fields that are missing or not text become null.
  static EmergencyInfo? tryFromMap(Map<String, Object?> map) {
    final familyId = map['family_id'];
    if (familyId is! String) return null;

    String? text(String key) {
      final value = map[key];
      return value is String ? value : null;
    }

    return EmergencyInfo(
      familyId: familyId,
      bloodGroup: text('blood_group'),
      allergies: text('allergies'),
      conditions: text('conditions'),
      emergencyContactName: text('emergency_contact_name'),
      emergencyContactPhone: text('emergency_contact_phone'),
      hospital: text('hospital'),
      doctorContact: text('doctor_contact'),
    );
  }
}
