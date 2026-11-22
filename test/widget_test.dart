import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:health_and_saftey_care/main.dart';
import 'package:health_and_saftey_care/models/family_space.dart';
import 'package:health_and_saftey_care/models/local_user.dart';
import 'package:health_and_saftey_care/providers/family_provider.dart';
import 'package:health_and_saftey_care/providers/session_provider.dart';

/// Signed-in user stub so MyApp skips onboarding and reaches MyHomePage.
class _SignedInUser extends CurrentUserNotifier {
  @override
  Future<LocalUser?> build() async {
    return const LocalUser(id: 'user-1', name: 'Test User', phone: '+10000000000');
  }
}

/// Active family stub so MyHomePage has a family space to show.
class _ActiveFamily extends FamilySpaceNotifier {
  @override
  Future<FamilySpace?> build() async {
    return FamilySpace(
      id: 'family-1',
      name: 'Test Family',
      inviteCode: 'TEST01',
      createdById: 'user-1',
      createdAt: DateTime(2024, 1, 1),
    );
  }
}

void main() {
  testWidgets('home screen shows appointments', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(_SignedInUser.new),
          familySpaceProvider.overrideWith(_ActiveFamily.new),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Dr. Mehta (Cardiology)'), 200);
    expect(find.text('Dr. Mehta (Cardiology)'), findsWidgets);
  });
}

