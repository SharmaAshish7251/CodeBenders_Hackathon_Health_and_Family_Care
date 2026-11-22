import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/appointment.dart';

/// In-memory store of booked appointments. Sample data only; nothing is persisted.
class AppointmentsNotifier extends Notifier<List<Appointment>> {
  @override
  List<Appointment> build() {
    final now = DateTime.now();
    return [
      Appointment(
        doctorName: 'Dr. Mehta (Cardiology)',
        dateTime: DateTime(now.year, now.month, now.day + 3, 10, 30),
        note: 'Bring last ECG report',
      ),
      Appointment(
        doctorName: 'City Diabetes Clinic',
        dateTime: DateTime(now.year, now.month, now.day + 10, 9, 0),
      ),
    ];
  }

  void add(Appointment appointment) {
    state = [...state, appointment];
  }
}

final appointmentsProvider =
    NotifierProvider<AppointmentsNotifier, List<Appointment>>(
  AppointmentsNotifier.new,
);
