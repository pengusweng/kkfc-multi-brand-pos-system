import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/new_order/presentation/widgets/customization_quantity_stepper.dart';

void main() {
  Widget buildStepper({
    required int quantity,
    required ValueChanged<int> onChanged,
    int min = 1,
    int max = 999,
    bool enabled = true,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: CustomizationQuantityStepper(
            quantity: quantity,
            onChanged: onChanged,
            min: min,
            max: max,
            enabled: enabled,
          ),
        ),
      ),
    );
  }

  group('CustomizationQuantityStepper - Typing', () {
    testWidgets('displays current quantity in the text field', (tester) async {
      await tester.pumpWidget(buildStepper(quantity: 3, onChanged: (_) {}));

      final textFieldFinder = find.byKey(
        const ValueKey('customize-quantity-field'),
      );
      expect(textFieldFinder, findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets(
      'allows user to type a new valid quantity and calls onChanged',
      (tester) async {
        int? updatedQuantity;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return buildStepper(
                quantity: updatedQuantity ?? 1,
                onChanged: (val) {
                  setState(() => updatedQuantity = val);
                },
              );
            },
          ),
        );

        final textFieldFinder = find.byKey(
          const ValueKey('customize-quantity-field'),
        );

        await tester.enterText(textFieldFinder, '12');
        await tester.pumpAndSettle();

        expect(updatedQuantity, 12);
        expect(find.text('12'), findsOneWidget);
      },
    );

    testWidgets(
      'clamps to min (1) when typing 0 or clearing field upon focus loss',
      (tester) async {
        int currentQuantity = 5;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return MaterialApp(
                home: Scaffold(
                  body: Column(
                    children: [
                      CustomizationQuantityStepper(
                        quantity: currentQuantity,
                        onChanged: (val) {
                          setState(() => currentQuantity = val);
                        },
                      ),
                      const TextField(key: ValueKey('other-field')),
                    ],
                  ),
                ),
              );
            },
          ),
        );

        final quantityField = find.byKey(
          const ValueKey('customize-quantity-field'),
        );
        final otherField = find.byKey(const ValueKey('other-field'));

        // Enter 0 and unfocus by tapping other field
        await tester.enterText(quantityField, '0');
        await tester.tap(otherField);
        await tester.pumpAndSettle();

        expect(currentQuantity, 1);
        expect(find.text('1'), findsOneWidget);

        // Enter empty string and unfocus
        await tester.enterText(quantityField, '');
        await tester.tap(otherField);
        await tester.pumpAndSettle();

        expect(currentQuantity, 1);
        expect(find.text('1'), findsOneWidget);
      },
    );

    testWidgets('clamps to max (999) when typing larger value', (tester) async {
      int currentQuantity = 1;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return buildStepper(
              quantity: currentQuantity,
              max: 99,
              onChanged: (val) {
                setState(() => currentQuantity = val);
              },
            );
          },
        ),
      );

      final quantityField = find.byKey(
        const ValueKey('customize-quantity-field'),
      );
      await tester.enterText(quantityField, '150');
      await tester.pumpAndSettle();

      // Clamped to max 99
      expect(currentQuantity, 99);
    });
  });

  group('CustomizationQuantityStepper - Single Tap', () {
    testWidgets('single tap on increment increases quantity by 1', (
      tester,
    ) async {
      int currentQuantity = 1;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return buildStepper(
              quantity: currentQuantity,
              onChanged: (val) {
                setState(() => currentQuantity = val);
              },
            );
          },
        ),
      );

      final incFinder = find.byKey(
        const ValueKey('customize-quantity-increment'),
      );
      await tester.tap(incFinder);
      await tester.pumpAndSettle();

      expect(currentQuantity, 2);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('single tap on decrement decreases quantity by 1', (
      tester,
    ) async {
      int currentQuantity = 4;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return buildStepper(
              quantity: currentQuantity,
              onChanged: (val) {
                setState(() => currentQuantity = val);
              },
            );
          },
        ),
      );

      final decFinder = find.byKey(
        const ValueKey('customize-quantity-decrement'),
      );
      await tester.tap(decFinder);
      await tester.pumpAndSettle();

      expect(currentQuantity, 3);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('decrement button is disabled when quantity is at min (1)', (
      tester,
    ) async {
      int currentQuantity = 1;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return buildStepper(
              quantity: currentQuantity,
              onChanged: (val) {
                setState(() => currentQuantity = val);
              },
            );
          },
        ),
      );

      final decFinder = find.byKey(
        const ValueKey('customize-quantity-decrement'),
      );
      await tester.tap(decFinder);
      await tester.pumpAndSettle();

      expect(currentQuantity, 1);
    });
  });

  group('CustomizationQuantityStepper - Hold to Continually Step', () {
    testWidgets(
      'holding increment continually increases quantity until release',
      (tester) async {
        int currentQuantity = 1;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return buildStepper(
                quantity: currentQuantity,
                onChanged: (val) {
                  setState(() => currentQuantity = val);
                },
              );
            },
          ),
        );

        final incFinder = find.byKey(
          const ValueKey('customize-quantity-increment'),
        );

        final gesture = await tester.startGesture(tester.getCenter(incFinder));
        await tester.pump();
        // Initial tap down: 1 -> 2
        expect(currentQuantity, 2);

        // Advance by hold delay (350ms)
        await tester.pump(const Duration(milliseconds: 350));
        expect(currentQuantity, 2);

        // Repeat tick 1 (80ms): 2 -> 3
        await tester.pump(const Duration(milliseconds: 80));
        expect(currentQuantity, 3);

        // Repeat tick 2 (80ms): 3 -> 4
        await tester.pump(const Duration(milliseconds: 80));
        expect(currentQuantity, 4);

        // Repeat tick 3 (80ms): 4 -> 5
        await tester.pump(const Duration(milliseconds: 80));
        expect(currentQuantity, 5);

        // Release finger
        await gesture.up();
        await tester.pumpAndSettle();

        // Advancing time further does not increase quantity after release
        await tester.pump(const Duration(milliseconds: 200));
        expect(currentQuantity, 5);
        expect(find.text('5'), findsOneWidget);
      },
    );

    testWidgets(
      'holding decrement continually decreases quantity and stops at min',
      (tester) async {
        int currentQuantity = 4;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return buildStepper(
                quantity: currentQuantity,
                onChanged: (val) {
                  setState(() => currentQuantity = val);
                },
              );
            },
          ),
        );

        final decFinder = find.byKey(
          const ValueKey('customize-quantity-decrement'),
        );

        final gesture = await tester.startGesture(tester.getCenter(decFinder));
        await tester.pump();
        // Initial step: 4 -> 3
        expect(currentQuantity, 3);

        // Advance by hold delay (350ms)
        await tester.pump(const Duration(milliseconds: 350));
        // Repeat tick 1 (80ms): 3 -> 2
        await tester.pump(const Duration(milliseconds: 80));
        expect(currentQuantity, 2);

        // Repeat tick 2 (80ms): 2 -> 1
        await tester.pump(const Duration(milliseconds: 80));
        expect(currentQuantity, 1);

        // Repeat tick 3 (80ms): minimum reached, stays at 1
        await tester.pump(const Duration(milliseconds: 80));
        expect(currentQuantity, 1);

        await gesture.up();
        await tester.pumpAndSettle();

        expect(currentQuantity, 1);
        expect(find.text('1'), findsOneWidget);
      },
    );
  });
}
