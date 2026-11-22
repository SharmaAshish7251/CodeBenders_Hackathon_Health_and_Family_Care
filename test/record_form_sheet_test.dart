import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_and_saftey_care/l10n/app_localizations.dart';
import 'package:health_and_saftey_care/screens/records_screen.dart';

void main() {
  testWidgets('RecordFormSheet shows category chips, quick tags, and custom type',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('hi')],
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const RecordFormSheet(
                    familyId: 'family-1',
                    uploaderId: 'user-1',
                  ),
                );
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap to open sheet
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    // Header and section titles
    expect(find.text('New record'), findsOneWidget);
    expect(find.text('Record Category'), findsOneWidget);

    // Category chips exist
    expect(find.text('Prescription'), findsWidgets);
    expect(find.text('Lab Report'), findsOneWidget);
    expect(find.text('Consultation'), findsOneWidget);

    // Tap 'Other' category chip to reveal custom type field
    await tester.tap(find.text('Other'));
    await tester.pumpAndSettle();

    // Custom type field is visible
    expect(find.text('Type (for example prescription or lab report)'), findsOneWidget);

    // Scroll to quick tag suggestions and tap
    await tester.ensureVisible(find.text('+ #Cardiology'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ #Cardiology'));
    await tester.pumpAndSettle();

    // Tag chip is active
    expect(find.text('#Cardiology'), findsOneWidget);

    // Scroll to and tap Cancel
    await tester.ensureVisible(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('New record'), findsNothing);
  });
}
