import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transwallet/widgets/dob_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'DobPickerSheet renders title, subtitle, Month/Year selectors and Confirm button',
    (WidgetTester tester) async {
      DateTime? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    selected = await showDobPicker(
                      context,
                      initialDate: DateTime(2002, 3, 15),
                    );
                  },
                  child: const Text('Open DOB'),
                );
              },
            ),
          ),
        ),
      );

      // Open DOB picker
      await tester.tap(find.text('Open DOB'));
      await tester.pumpAndSettle();

      // Verify Title and Subtitle
      expect(find.text('Date of Birth'), findsOneWidget);
      expect(find.text('Select your date of birth'), findsOneWidget);

      // Verify Month and Year fields
      expect(find.text('March'), findsWidgets);
      expect(find.text('2002'), findsWidgets);

      // Verify Weekdays Mon to Sun
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);

      // Confirm button
      expect(find.text('Confirm'), findsOneWidget);

      // Tap confirm
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      // Verify returned date matches initial date
      expect(selected, isNotNull);
      expect(selected!.year, 2002);
      expect(selected!.month, 3);
      expect(selected!.day, 15);
    },
  );

  testWidgets('DobPickerSheet month change clamps day safely for leap year', (
    WidgetTester tester,
  ) async {
    DateTime? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  // Jan 31, 2004 (2004 is a leap year)
                  selected = await showDobPicker(
                    context,
                    initialDate: DateTime(2004, 1, 31),
                  );
                },
                child: const Text('Open Leap DOB'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Leap DOB'));
    await tester.pumpAndSettle();

    // Tap Month field to open month picker
    await tester.tap(find.text('January'));
    await tester.pumpAndSettle();

    expect(find.text('Select Month'), findsOneWidget);

    // Tap February ('Feb')
    await tester.tap(find.text('Feb'));
    await tester.pumpAndSettle();

    // Since 2004 is leap year, 31st January clamped to 29th February
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(selected, isNotNull);
    expect(selected!.year, 2004);
    expect(selected!.month, 2);
    expect(selected!.day, 29);
  });

  testWidgets('DobPickerSheet year change updates calendar and clamps safely', (
    WidgetTester tester,
  ) async {
    DateTime? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  selected = await showDobPicker(
                    context,
                    initialDate: DateTime(2004, 2, 29), // Leap year Feb 29
                  );
                },
                child: const Text('Open Year DOB'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Year DOB'));
    await tester.pumpAndSettle();

    // Tap Year field to open year picker
    await tester.tap(find.text('2004'));
    await tester.pumpAndSettle();

    expect(find.text('Select Year'), findsOneWidget);

    // Select 2023 (not a leap year)
    await tester.tap(find.text('2023'));
    await tester.pumpAndSettle();

    // Confirm
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    // Clamped to 28 Feb 2023
    expect(selected, isNotNull);
    expect(selected!.year, 2023);
    expect(selected!.month, 2);
    expect(selected!.day, 28);
  });

  testWidgets('DobPickerSheet chevron navigation works', (
    WidgetTester tester,
  ) async {
    DateTime? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  selected = await showDobPicker(
                    context,
                    initialDate: DateTime(2000, 5, 10),
                  );
                },
                child: const Text('Open Chevron DOB'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Chevron DOB'));
    await tester.pumpAndSettle();

    // Tap previous month chevron
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();

    // Month should now be April (4)
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(selected, isNotNull);
    expect(selected!.year, 2000);
    expect(selected!.month, 4);
    expect(selected!.day, 10);
  });

  testWidgets('DobPickerSheet enforces 18+ age restriction', (
    WidgetTester tester,
  ) async {
    DateTime? selected;
    // Date that is 10 years old (under 18)
    final under18Date = DateTime(DateTime.now().year - 10, 1, 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  selected = await showDobPicker(
                    context,
                    initialDate: under18Date,
                  );
                },
                child: const Text('Open Underage DOB'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Underage DOB'));
    await tester.pumpAndSettle();

    // Verify 18+ badge is displayed
    expect(find.text(''), findsOneWidget);

    // Initial date should have been clamped to max allowed (18 years ago)
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(selected, isNotNull);
    expect(isUnderAge(selected!), isFalse);
  });
}
