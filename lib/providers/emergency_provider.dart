import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/emergency_info.dart';
import 'family_provider.dart';
import 'session_provider.dart';

/// Emergency details for the active family. Null when none are saved yet.
class EmergencyInfoNotifier extends AsyncNotifier<EmergencyInfo?> {
  @override
  Future<EmergencyInfo?> build() async {
    final family = await ref.watch(familySpaceProvider.future);
    if (family == null) return null;
    return ref.watch(emergencyRepositoryProvider).get(family.id);
  }

  /// Saves the details. Only admins and caregivers may save; the repository
  /// enforces this.
  Future<void> save(EmergencyInfo info) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;
    await ref
        .read(emergencyRepositoryProvider)
        .save(actorId: user.id, info: info);
    ref.invalidateSelf();
    ref.invalidate(activityProvider);
  }
}

final emergencyInfoProvider =
    AsyncNotifierProvider<EmergencyInfoNotifier, EmergencyInfo?>(
  EmergencyInfoNotifier.new,
);
