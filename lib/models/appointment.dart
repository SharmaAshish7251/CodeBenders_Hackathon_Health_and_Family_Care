/// A booked doctor or clinic appointment.
class Appointment {
  const Appointment({
    required this.doctorName,
    required this.dateTime,
    this.note,
  });

  final String doctorName;
  final DateTime dateTime;
  final String? note;

  String get formattedDateTime {
    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '${formatDate(dateTime)} $time';
  }
}

/// Formats a date as YYYY-MM-DD.
String formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
