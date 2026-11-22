import 'package:flutter/foundation.dart';

import 'enum_names.dart';

/// Consent purposes shown in onboarding and Settings (PRD F19). All are
/// unticked by default.
enum ConsentPurpose { dataStorage, ocrProcessing, whatsappSharing }

/// A single consent decision for one user and one purpose.
@immutable
class ConsentRecord {
  const ConsentRecord({
    required this.userId,
    required this.purpose,
    required this.granted,
    required this.updatedAt,
  });

  final String userId;
  final ConsentPurpose purpose;
  final bool granted;
  final DateTime updatedAt;

  Map<String, Object?> toMap() {
    return {
      'user_id': userId,
      'purpose': purpose.name,
      'granted': granted ? 1 : 0,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Returns null when required fields are missing or malformed.
  static ConsentRecord? tryFromMap(Map<String, Object?> map) {
    final userId = map['user_id'];
    final purpose = enumFromName(
      ConsentPurpose.values,
      map['purpose'] as String?,
    );
    final granted = map['granted'];
    final updatedAt = map['updated_at'];
    if (userId is! String || purpose == null) return null;
    if (granted is! int || updatedAt is! int) return null;
    return ConsentRecord(
      userId: userId,
      purpose: purpose,
      granted: granted == 1,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
    );
  }
}
