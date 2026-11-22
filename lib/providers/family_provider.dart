import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_event.dart';
import '../models/consent.dart';
import '../models/family_member.dart';
import '../models/family_space.dart';
import 'session_provider.dart';

/// The active family space on this device (null until family setup).
class FamilySpaceNotifier extends AsyncNotifier<FamilySpace?> {
  @override
  Future<FamilySpace?> build() {
    return ref.watch(familyRepositoryProvider).currentFamily();
  }

  Future<FamilySpace> createFamily(String name) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) throw StateError('Sign in before creating a family');
    final family = await ref.read(familyRepositoryProvider).createFamily(
          name: name.trim(),
          adminId: user.id,
          adminName: user.name,
          adminPhone: user.phone,
        );
    state = AsyncData(family);
    ref.invalidate(membersProvider);
    ref.invalidate(activityProvider);
    return family;
  }

  /// Joins the family with [code] as a Viewer. Throws NotFoundException when
  /// no family has that invite code.
  Future<FamilySpace> joinByCode(String code) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) throw StateError('Sign in before joining a family');
    final family = await ref.read(familyRepositoryProvider).joinByCode(
          code: code,
          userId: user.id,
          userName: user.name,
          userPhone: user.phone,
        );
    state = AsyncData(family);
    ref.invalidate(membersProvider);
    ref.invalidate(activityProvider);
    return family;
  }
}

final familySpaceProvider =
    AsyncNotifierProvider<FamilySpaceNotifier, FamilySpace?>(
  FamilySpaceNotifier.new,
);

/// Members of the active family space.
class MembersNotifier extends AsyncNotifier<List<FamilyMember>> {
  @override
  Future<List<FamilyMember>> build() async {
    final family = await ref.watch(familySpaceProvider.future);
    if (family == null) return const [];
    return ref.watch(familyRepositoryProvider).members(family.id);
  }

  Future<void> changeRole(String memberId, Role role) async {
    final family = await ref.read(familySpaceProvider.future);
    final user = await ref.read(currentUserProvider.future);
    if (family == null || user == null) return;
    await ref.read(familyRepositoryProvider).changeMemberRole(
          familyId: family.id,
          actorId: user.id,
          memberId: memberId,
          role: role,
        );
    ref.invalidateSelf();
    ref.invalidate(activityProvider);
  }

  Future<void> removeMember(String memberId) async {
    final family = await ref.read(familySpaceProvider.future);
    final user = await ref.read(currentUserProvider.future);
    if (family == null || user == null) return;
    await ref.read(familyRepositoryProvider).removeMember(
          familyId: family.id,
          actorId: user.id,
          memberId: memberId,
        );
    ref.invalidateSelf();
    ref.invalidate(activityProvider);
  }
}

final membersProvider =
    AsyncNotifierProvider<MembersNotifier, List<FamilyMember>>(
  MembersNotifier.new,
);

/// Role of the signed-in user in the active family. Null if not a member.
/// The UI uses this only to hide controls; repositories check roles again.
final currentRoleProvider = Provider<Role?>((ref) {
  final user = ref.watch(currentUserProvider).value;
  final members = ref.watch(membersProvider).value ?? const <FamilyMember>[];
  for (final member in members) {
    if (member.id == user?.id) return member.role;
  }
  return null;
});

/// Consent choices for the signed-in user (PRD F19).
class ConsentNotifier extends AsyncNotifier<Map<ConsentPurpose, bool>> {
  @override
  Future<Map<ConsentPurpose, bool>> build() async {
    final user = await ref.watch(currentUserProvider.future);
    if (user == null) {
      return {for (final purpose in ConsentPurpose.values) purpose: false};
    }
    return ref.watch(familyRepositoryProvider).consents(user.id);
  }

  Future<void> setConsent(ConsentPurpose purpose, bool granted) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;
    await ref.read(familyRepositoryProvider).setConsent(
          userId: user.id,
          purpose: purpose,
          granted: granted,
        );
    ref.invalidateSelf();
  }

  /// Saves all purposes for [userId]. Used right after sign-in, when the
  /// user state is still settling, so the id is passed in explicitly.
  Future<void> saveAll(String userId, Map<ConsentPurpose, bool> values) async {
    final repository = ref.read(familyRepositoryProvider);
    for (final entry in values.entries) {
      await repository.setConsent(
        userId: userId,
        purpose: entry.key,
        granted: entry.value,
      );
    }
    ref.invalidateSelf();
  }
}

final consentProvider =
    AsyncNotifierProvider<ConsentNotifier, Map<ConsentPurpose, bool>>(
  ConsentNotifier.new,
);

/// The last 20 activity events for the active family (PRD F7).
class ActivityNotifier extends AsyncNotifier<List<ActivityEvent>> {
  @override
  Future<List<ActivityEvent>> build() async {
    final family = await ref.watch(familySpaceProvider.future);
    if (family == null) return const [];
    return ref.watch(activityRepositoryProvider).recent(family.id, limit: 20);
  }
}

final activityProvider =
    AsyncNotifierProvider<ActivityNotifier, List<ActivityEvent>>(
  ActivityNotifier.new,
);
