import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../data/database.dart';
import '../models/local_user.dart';
import '../repositories/activity_repository.dart';
import '../repositories/analytics_repository.dart';
import '../repositories/emergency_repository.dart';
import '../repositories/family_repository.dart';
import '../repositories/medicine_repository.dart';
import '../repositories/record_repository.dart';
import '../repositories/task_repository.dart';
import 'settings_provider.dart';

const _userIdKey = 'local_user_id';
const _userNameKey = 'local_user_name';
const _userPhoneKey = 'local_user_phone';

/// Opens the local database once. Everything that stores data depends on it.
final appDatabaseProvider = FutureProvider<Database>((ref) {
  return openCareDatabase();
});

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return SqfliteFamilyRepository(ref.watch(appDatabaseProvider.future));
});

final recordRepositoryProvider = Provider<RecordRepository>((ref) {
  return SqfliteRecordRepository(ref.watch(appDatabaseProvider.future));
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return SqfliteTaskRepository(ref.watch(appDatabaseProvider.future));
});

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return SqfliteActivityRepository(ref.watch(appDatabaseProvider.future));
});

final medicineRepositoryProvider = Provider<MedicineRepository>((ref) {
  return SqfliteMedicineRepository(ref.watch(appDatabaseProvider.future));
});

final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  return SqfliteEmergencyRepository(ref.watch(appDatabaseProvider.future));
});

/// Local analytics log (PRD F20). Logging is skipped when the user opted out.
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return SqfliteAnalyticsRepository(
    ref.watch(appDatabaseProvider.future),
    isAnalyticsEnabledStored,
  );
});

/// The signed-in user on this device.
///
/// AUTH STUB: sign-in is local only. It takes a name and phone and stores
/// them on the device. OTP verification is a stub and is not implemented yet.
/// The PRD's Firebase Auth phone OTP is out of scope for the local-first build.
class CurrentUserNotifier extends AsyncNotifier<LocalUser?> {
  @override
  Future<LocalUser?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_userIdKey);
    final name = prefs.getString(_userNameKey);
    final phone = prefs.getString(_userPhoneKey);
    if (id == null || name == null || phone == null) return null;
    return LocalUser(id: id, name: name, phone: phone);
  }

  /// Local sign-in stub. OTP is a stub: no code is sent or checked.
  Future<LocalUser> signIn({required String name, required String phone}) async {
    final user = LocalUser(
      id: newEntityId(),
      name: name.trim(),
      phone: phone.trim(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, user.id);
    await prefs.setString(_userNameKey, user.name);
    await prefs.setString(_userPhoneKey, user.phone);
    state = AsyncData(user);
    return user;
  }

  /// Switches the active signed-in user (used for demo persona switching).
  Future<void> switchUser(LocalUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, user.id);
    await prefs.setString(_userNameKey, user.name);
    await prefs.setString(_userPhoneKey, user.phone);
    state = AsyncData(user);
  }
}

final currentUserProvider =
    AsyncNotifierProvider<CurrentUserNotifier, LocalUser?>(
  CurrentUserNotifier.new,
);
