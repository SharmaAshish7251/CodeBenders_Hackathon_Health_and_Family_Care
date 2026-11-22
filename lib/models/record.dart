import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'enum_names.dart';

/// Who can see a record (PRD F2: "Caregivers only" hides it from Viewers).
enum RecordVisibility { family, caregiversOnly }

/// A stored care document: prescription, lab report, discharge note and so on.
@immutable
class CareRecord {
  const CareRecord({
    required this.id,
    required this.familyId,
    required this.title,
    required this.date,
    required this.type,
    required this.tags,
    required this.visibility,
    required this.uploaderId,
    this.attachmentPath,
    this.ocrText,
  });

  final String id;
  final String familyId;
  final String title;
  final DateTime date;
  final String type;
  final List<String> tags;
  final RecordVisibility visibility;
  final String uploaderId;

  /// Local path of the original scanned image, if the record came from OCR.
  final String? attachmentPath;

  /// Text read from the image by on-device OCR. Used for search.
  final String? ocrText;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'family_id': familyId,
      'title': title,
      'date': date.millisecondsSinceEpoch,
      'type': type,
      'tags': jsonEncode(tags),
      'visibility': visibility.name,
      'uploader_id': uploaderId,
      'attachment_path': attachmentPath,
      'ocr_text': ocrText,
    };
  }

  /// Returns null when required fields are missing or malformed.
  static CareRecord? tryFromMap(Map<String, Object?> map) {
    final id = map['id'];
    final familyId = map['family_id'];
    final title = map['title'];
    final date = map['date'];
    final type = map['type'];
    final uploaderId = map['uploader_id'];
    final visibility = enumFromName(
      RecordVisibility.values,
      map['visibility'] as String?,
    );
    if (id is! String || familyId is! String || title is! String) return null;
    if (date is! int || type is! String || uploaderId is! String) return null;
    if (visibility == null) return null;
    return CareRecord(
      id: id,
      familyId: familyId,
      title: title,
      date: DateTime.fromMillisecondsSinceEpoch(date),
      type: type,
      tags: _decodeTags(map['tags']),
      visibility: visibility,
      uploaderId: uploaderId,
      attachmentPath: _optionalText(map['attachment_path']),
      ocrText: _optionalText(map['ocr_text']),
    );
  }

  static String? _optionalText(Object? raw) => raw is String ? raw : null;

  static List<String> _decodeTags(Object? raw) {
    if (raw is! String) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is String) item,
      ];
    } on FormatException {
      return const [];
    }
  }
}
