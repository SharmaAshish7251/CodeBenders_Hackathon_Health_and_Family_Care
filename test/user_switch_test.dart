import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:health_and_saftey_care/data/demo_data_seeder.dart';
import 'package:health_and_saftey_care/models/family_member.dart';
import 'package:health_and_saftey_care/providers/family_provider.dart';
import 'package:health_and_saftey_care/providers/session_provider.dart';
import 'package:health_and_saftey_care/widgets/user_switch_sheet.dart';

class _MockMembersNotifier extends MembersNotifier {
  @override
  Future<List<FamilyMember>> build() async {
    return [
      const FamilyMember(
        id: DemoDataSeeder.userRahulId,
        familyId: DemoDataSeeder.familyId,
        name: DemoDataSeeder.userRahulName,
        role: Role.admin,
      ),
      const FamilyMember(
        id: 'demo-member-priya',
        familyId: DemoDataSeeder.familyId,
        name: 'Priya (Jaipur)',
        role: Role.caregiver,
      ),
      const FamilyMember(
        id: 'demo-member-ankit',
        familyId: DemoDataSeeder.familyId,
        name: 'Ankit (Relative)',
        role: Role.viewer,
      ),
    ];
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('UserSwitchSheet displays personas and switches active user',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          membersProvider.overrideWith(_MockMembersNotifier.new),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                final user = ref.watch(currentUserProvider).value;
                final role = ref.watch(currentRoleProvider);

                return Column(
                  children: [
                    Text('ActiveUser: ${user?.name ?? "None"}'),
                    Text('ActiveRole: ${role?.name ?? "None"}'),
                    ElevatedButton(
                      onPressed: () => UserSwitchSheet.show(context),
                      child: const Text('Open Switcher'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial state
    expect(find.text('ActiveUser: None'), findsOneWidget);

    // Open switch sheet
    await tester.tap(find.text('Open Switcher'));
    await tester.pumpAndSettle();

    // Verify personas exist
    expect(find.text('Switch Demo Profile'), findsOneWidget);
    expect(find.text('DEMO MODE'), findsOneWidget);
    expect(find.text('Rahul (Bangalore)'), findsOneWidget);
    expect(find.text('Priya (Jaipur)'), findsOneWidget);
    expect(find.text('Sunita (Nurse)'), findsOneWidget);
    expect(find.text('Ankit (Relative)'), findsOneWidget);
    expect(find.text('Ramesh Sharma'), findsOneWidget);

    // Tap Priya (Caregiver)
    await tester.tap(find.text('Priya (Jaipur)'));
    await tester.pumpAndSettle();

    // Sheet dismissed, user and role updated
    expect(find.text('ActiveUser: Priya (Jaipur)'), findsOneWidget);
    expect(find.text('ActiveRole: caregiver'), findsOneWidget);

    // Open switcher again and switch to Ankit (Viewer)
    await tester.tap(find.text('Open Switcher'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Ankit (Relative)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ankit (Relative)'));
    await tester.pumpAndSettle();

    // Now active user is Ankit and role is viewer
    expect(find.text('ActiveUser: Ankit (Relative)'), findsOneWidget);
    expect(find.text('ActiveRole: viewer'), findsOneWidget);
  });
}
