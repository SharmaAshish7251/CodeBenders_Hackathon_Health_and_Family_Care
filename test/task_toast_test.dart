import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_and_saftey_care/widgets/care_toast.dart';

void main() {
  group('CareToast tests', () {
    testWidgets('showTaskCompleted displays celebration toast with UNDO action',
        (tester) async {
      bool undoTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  CareToast.showTaskCompleted(
                    context,
                    taskTitle: 'Give morning BP medication',
                    onUndo: () => undoTapped = true,
                  );
                },
                child: const Text('Complete Task'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Complete Task'));
      await tester.pump(); // Start snackbar animation
      await tester.pump(const Duration(milliseconds: 300)); // Visible

      expect(find.text('Task Completed!'), findsOneWidget);
      expect(find.text('🎉'), findsOneWidget);
      expect(find.text('Give morning BP medication'), findsOneWidget);
      expect(find.text('UNDO'), findsOneWidget);

      await tester.tap(find.text('UNDO'));
      expect(undoTapped, isTrue);
    });

    testWidgets('showTaskSnoozed displays snooze toast with duration info',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  CareToast.showTaskSnoozed(
                    context,
                    taskTitle: 'Evening walk with Father',
                    newDueText: 'Today, 6:30 PM',
                  );
                },
                child: const Text('Snooze Task'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Snooze Task'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Snoozed for 1 hour'), findsOneWidget);
      expect(find.textContaining('Evening walk with Father'), findsOneWidget);
      expect(find.textContaining('Today, 6:30 PM'), findsOneWidget);
    });

    testWidgets('showTaskSkipped displays skipped toast', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  CareToast.showTaskSkipped(
                    context,
                    taskTitle: 'Check oxygen saturation',
                  );
                },
                child: const Text('Skip Task'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Skip Task'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Task Skipped'), findsOneWidget);
      expect(find.text('Check oxygen saturation'), findsOneWidget);
    });

    testWidgets('showSuccess displays custom title and subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  CareToast.showSuccess(
                    context,
                    title: 'Task Reassigned',
                    subtitle: 'Order Telmisartan Refill → Rahul (Bangalore)',
                  );
                },
                child: const Text('Reassign Task'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Reassign Task'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Task Reassigned'), findsOneWidget);
      expect(
        find.text('Order Telmisartan Refill → Rahul (Bangalore)'),
        findsOneWidget,
      );
    });
  });
}
