import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_and_saftey_care/l10n/app_localizations.dart';
import 'package:health_and_saftey_care/models/consent.dart';
import 'package:health_and_saftey_care/screens/sign_in_screen.dart';

void main() {
  testWidgets('Sign-in screen toggles between Explore Demo and Setup Manually',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en')],
          home: Scaffold(
            body: SignInScreen(
              consents: {
                ConsentPurpose.dataStorage: true,
                ConsentPurpose.ocrProcessing: true,
                ConsentPurpose.whatsappSharing: true,
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Default: Demo mode is selected
    expect(find.text('Explore Demo'), findsOneWidget);
    expect(find.text('Setup Manually'), findsOneWidget);
    expect(find.text('Instant Live Demo Space'), findsOneWidget);
    expect(find.text('Explore Demo Workspace'), findsOneWidget);

    // Tap "Setup Manually"
    await tester.tap(find.text('Setup Manually'));
    await tester.pumpAndSettle();

    // Now Manual Setup form is visible
    expect(find.text('Enter Your Information'), findsOneWidget);
    expect(find.text('Continue to Family Setup'), findsOneWidget);

    // Tap back to "Explore Demo"
    await tester.tap(find.text('Explore Demo'));
    await tester.pumpAndSettle();

    expect(find.text('Instant Live Demo Space'), findsOneWidget);
  });
}
