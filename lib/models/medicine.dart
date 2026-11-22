import 'package:flutter/foundation.dart';

/// A medicine kept in the family stock (PRD F6).
///
/// [scheduleNote] is free text the user types (for example "1 tablet after
/// breakfast"). It is stored as entered and is never treated as medical advice.
@immutable
class Medicine {
  const Medicine({
    required this.id,
    required this.familyId,
    required this.name,
    required this.quantityOnHand,
    required this.dailyUsage,
    required this.refillThresholdDays,
    this.scheduleNote,
  });

  final String id;
  final String familyId;
  final String name;
  final String? scheduleNote;
  final int quantityOnHand;
  final int dailyUsage;
  final int refillThresholdDays;

  /// Whole days of stock left at the current daily usage.
  /// Null when daily usage is 0, because the stock never runs out.
  int? get daysRemaining {
    if (dailyUsage <= 0) return null;
    return quantityOnHand ~/ dailyUsage;
  }

  Medicine copyWith({
    String? name,
    String? scheduleNote,
    int? quantityOnHand,
    int? dailyUsage,
    int? refillThresholdDays,
  }) {
    return Medicine(
      id: id,
      familyId: familyId,
      name: name ?? this.name,
      scheduleNote: scheduleNote ?? this.scheduleNote,
      quantityOnHand: quantityOnHand ?? this.quantityOnHand,
      dailyUsage: dailyUsage ?? this.dailyUsage,
      refillThresholdDays: refillThresholdDays ?? this.refillThresholdDays,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'family_id': familyId,
      'name': name,
      'schedule_note': scheduleNote,
      'quantity_on_hand': quantityOnHand,
      'daily_usage': dailyUsage,
      'refill_threshold_days': refillThresholdDays,
    };
  }

  /// Returns null when required fields are missing or malformed.
  static Medicine? tryFromMap(Map<String, Object?> map) {
    final id = map['id'];
    final familyId = map['family_id'];
    final name = map['name'];
    final quantityOnHand = map['quantity_on_hand'];
    final dailyUsage = map['daily_usage'];
    final refillThresholdDays = map['refill_threshold_days'];
    if (id is! String || familyId is! String || name is! String) return null;
    if (quantityOnHand is! int || quantityOnHand < 0) return null;
    if (dailyUsage is! int || dailyUsage < 0) return null;
    if (refillThresholdDays is! int || refillThresholdDays < 0) return null;

    final scheduleNote = map['schedule_note'];
    return Medicine(
      id: id,
      familyId: familyId,
      name: name,
      scheduleNote: scheduleNote is String ? scheduleNote : null,
      quantityOnHand: quantityOnHand,
      dailyUsage: dailyUsage,
      refillThresholdDays: refillThresholdDays,
    );
  }
}
