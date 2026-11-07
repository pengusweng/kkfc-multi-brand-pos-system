import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/shared/widgets/text_field/text_field.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      theme: counterTheme,
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('KkfcStandardTextField', () {
    testWidgets('renders label, hint, and handles text entry', (tester) async {
      String? enteredText;

      await tester.pumpWidget(
        buildTestWidget(
          KkfcTextField(
            label: 'Table Number',
            hint: 'For example: Table 4',
            onChanged: (val) => enteredText = val,
          ),
        ),
      );

      expect(find.text('Table Number'), findsOneWidget);
      expect(find.text('For example: Table 4'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Table 7');
      expect(enteredText, 'Table 7');
    });

    testWidgets('displays error message and red border on error',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const KkfcTextField(
            label: 'Table Number',
            hasError: true,
            errorText: 'Table is currently occupied',
          ),
        ),
      );

      expect(find.text('Table is currently occupied'), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.enabledBorder?.borderSide.color,
          const Color(0xFFB3261E));
    });

    testWidgets('respects disabled state and shows disabled text',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const KkfcTextField(
            label: 'GrabFood Order Ref',
            enabled: false,
            disabledText: 'Not used for Dine-in',
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
      expect(find.text('Not used for Dine-in'), findsOneWidget);
    });
  });

  group('KkfcTextArea', () {
    testWidgets('renders multi-line input and accepts text', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const KkfcTextArea(
            label: 'Kitchen Feedback',
            hint: 'For example: under-cooked, missing sauce',
            minLines: 3,
          ),
        ),
      );

      expect(find.text('Kitchen Feedback'), findsOneWidget);
      expect(find.text('For example: under-cooked, missing sauce'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField),
        'Rice portion short;\nplate again',
      );
      expect(find.text('Rice portion short;\nplate again'), findsOneWidget);
    });
  });

  group('KkfcSearchField', () {
    testWidgets('renders pill search input and clear button clears text',
        (tester) async {
      var cleared = false;

      await tester.pumpWidget(
        buildTestWidget(
          KkfcSearchField(
            hint: 'Search item code or name',
            shape: KkfcTextFieldShape.pill,
            onClear: () => cleared = true,
          ),
        ),
      );

      expect(find.text('Search item code or name'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Dumpling');
      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(cleared, isTrue);
      expect(find.text('Dumpling'), findsNothing);
    });
  });

  group('KkfcNumericField', () {
    testWidgets('renders centered tabular numeric input', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const KkfcNumericField(
            hint: 'Enter the count',
            textAlign: TextAlign.center,
          ),
        ),
      );

      expect(find.text('Enter the count'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '75');
      expect(find.text('75'), findsOneWidget);
    });
  });

  group('KkfcSelectField', () {
    testWidgets('renders dropdown with selected item and chevron',
        (tester) async {
      String? selected = 'channels';

      await tester.pumpWidget(
        buildTestWidget(
          KkfcSelectField<String>(
            label: 'Filter',
            value: selected,
            items: const [
              DropdownMenuItem(value: 'channels', child: Text('All channels')),
              DropdownMenuItem(value: 'dine_in', child: Text('Dine In')),
            ],
            onChanged: (val) => selected = val,
          ),
        ),
      );

      expect(find.text('Filter'), findsOneWidget);
      expect(find.text('All channels'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });
  });

  group('KkfcSunkenField', () {
    testWidgets('renders static warm sand reference code', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const KkfcSunkenField(
            label: 'Package Code',
            text: 'REF-PACK',
            isMonospace: true,
          ),
        ),
      );

      expect(find.text('Package Code'), findsOneWidget);
      expect(find.text('REF-PACK'), findsOneWidget);
    });
  });
}
