import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// On-device text recognition for scanned care documents (PRD F9). The image
/// never leaves the device.
class OcrService {
  const OcrService();

  /// Reads the text in the image at [imagePath]. The recognizer is closed
  /// after every call, even when recognition fails.
  ///
  /// Devanagari: not enabled. It would need a second recognizer with
  /// TextRecognitionScript.devanagari, which could not be checked because the
  /// package source is not in the pub cache yet (pub get has not run).
  Future<String> recognise(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final input = InputImage.fromFilePath(imagePath);
      final result = await recognizer.processImage(input);
      return result.text;
    } finally {
      await recognizer.close();
    }
  }
}

const _monthNumbers = {
  'jan': 1,
  'feb': 2,
  'mar': 3,
  'apr': 4,
  'may': 5,
  'jun': 6,
  'jul': 7,
  'aug': 8,
  'sep': 9,
  'oct': 10,
  'nov': 11,
  'dec': 12,
};

/// dd/mm/yyyy or dd-mm-yyyy. The lookarounds stop it matching inside longer
/// digit runs.
final _numericDatePattern =
    RegExp(r'(?<!\d)(\d{1,2})[/-](\d{1,2})[/-](\d{4})(?!\d)');

/// dd Mon yyyy, for example 5 Jan 2024 or 05 March 2024.
final _namedDatePattern =
    RegExp(r'(?<!\d)(\d{1,2})\s+([A-Za-z]{3,9})\.?,?\s+(\d{4})(?!\d)');

/// Finds dates in [text] for the review screen to suggest. Returns them in the
/// order they appear, without duplicates. Impossible dates such as 31/02/2024
/// are skipped. Nothing is saved from this result; the user must pick a date.
List<DateTime> extractDateCandidates(String text) {
  final found = <({int position, DateTime date})>[];

  for (final match in _numericDatePattern.allMatches(text)) {
    final date = _buildDate(
      day: int.parse(match.group(1)!),
      month: int.parse(match.group(2)!),
      year: int.parse(match.group(3)!),
    );
    if (date != null) found.add((position: match.start, date: date));
  }

  for (final match in _namedDatePattern.allMatches(text)) {
    final monthName = match.group(2)!.toLowerCase();
    if (monthName.length < 3) continue;
    final month = _monthNumbers[monthName.substring(0, 3)];
    if (month == null) continue;
    final date = _buildDate(
      day: int.parse(match.group(1)!),
      month: month,
      year: int.parse(match.group(3)!),
    );
    if (date != null) found.add((position: match.start, date: date));
  }

  found.sort((a, b) => a.position.compareTo(b.position));
  final seen = <String>{};
  final dates = <DateTime>[];
  for (final entry in found) {
    final key = '${entry.date.year}-${entry.date.month}-${entry.date.day}';
    if (seen.add(key)) dates.add(entry.date);
  }
  return dates;
}

/// Returns the date, or null when the day or month is out of range. Dart rolls
/// over invalid dates such as 31 February, so the result is checked again.
DateTime? _buildDate({
  required int day,
  required int month,
  required int year,
}) {
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  final date = DateTime(year, month, day);
  if (date.day != day || date.month != month) return null;
  return date;
}
