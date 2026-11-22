import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/medicine.dart';
import 'family_provider.dart';
import 'session_provider.dart';

/// Medicines in the active family, ordered by name.
class MedicinesNotifier extends AsyncNotifier<List<Medicine>> {
  @override
  Future<List<Medicine>> build() async {
    final family = await ref.watch(familySpaceProvider.future);
    if (family == null) return const [];
    return ref.watch(medicineRepositoryProvider).list(family.id);
  }

  Future<void> add(Medicine medicine) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;
    await ref
        .read(medicineRepositoryProvider)
        .add(actorId: user.id, medicine: medicine);
    ref.invalidateSelf();
    ref.invalidate(activityProvider);
  }

  Future<void> updateStock(String medicineId, int quantityOnHand) async {
    final family = await ref.read(familySpaceProvider.future);
    final user = await ref.read(currentUserProvider.future);
    if (family == null || user == null) return;
    await ref.read(medicineRepositoryProvider).updateStock(
          familyId: family.id,
          actorId: user.id,
          medicineId: medicineId,
          quantityOnHand: quantityOnHand,
        );
    ref.invalidateSelf();
    ref.invalidate(activityProvider);
  }

  Future<void> remove(String medicineId) async {
    final family = await ref.read(familySpaceProvider.future);
    final user = await ref.read(currentUserProvider.future);
    if (family == null || user == null) return;
    await ref.read(medicineRepositoryProvider).delete(
          familyId: family.id,
          actorId: user.id,
          medicineId: medicineId,
        );
    ref.invalidateSelf();
    ref.invalidate(activityProvider);
  }
}

final medicinesProvider =
    AsyncNotifierProvider<MedicinesNotifier, List<Medicine>>(
  MedicinesNotifier.new,
);
