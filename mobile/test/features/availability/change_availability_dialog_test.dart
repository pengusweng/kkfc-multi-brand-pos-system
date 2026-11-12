import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/features/availability/presentation/widgets/change_availability_dialog.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';

void main() {
  const availableItem = MenuItem(
    id: 'item-1',
    name: 'Gamcheon Samgyupsal Rice Bowl',
    description: 'Grilled pork belly with kimchi and rice',
    pricesCentavos: {MenuChannel.dineIn: 25000},
    availability: {MenuChannel.dineIn: MenuAvailability.available},
  );

  const unavailableItem = MenuItem(
    id: 'item-2',
    name: 'Gamcheon Bulgogi Rice Bowl',
    description: 'Marinated beef with rice',
    pricesCentavos: {MenuChannel.dineIn: 28000},
    availability: {MenuChannel.dineIn: MenuAvailability.stockout},
  );

  Widget buildDialogHost({
    required MenuItem item,
    MenuChannel channel = MenuChannel.dineIn,
    Future<void> Function(bool availability)? onUpdateAvailability,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: counterTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showChangeAvailabilityDialog(
                  context,
                  item: item,
                  channel: channel,
                  onUpdateAvailability: onUpdateAvailability,
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ),
    );
  }

  group('ChangeAvailabilityDialog UI and interactions', () {
    testWidgets('renders correctly when item is currently available', (
      tester,
    ) async {
      await tester.pumpWidget(buildDialogHost(item: availableItem));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(ChangeAvailabilityDialog), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text('Make item unavailable?'), findsOneWidget);
      expect(find.text('Gamcheon Samgyupsal Rice Bowl'), findsOneWidget);
      expect(
        find.text('Dine-in · Other availability restrictions still apply.'),
        findsOneWidget,
      );
      expect(find.text('Mark unavailable'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('renders correctly when item is currently unavailable', (
      tester,
    ) async {
      await tester.pumpWidget(buildDialogHost(item: unavailableItem));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(ChangeAvailabilityDialog), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text('Make item available?'), findsOneWidget);
      expect(find.text('Gamcheon Bulgogi Rice Bowl'), findsOneWidget);
      expect(find.text('Mark available'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('tapping Cancel dismisses dialog without updating', (
      tester,
    ) async {
      bool updateCalled = false;
      await tester.pumpWidget(
        buildDialogHost(
          item: availableItem,
          onUpdateAvailability: (_) async => updateCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('change-availability-cancel-button')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChangeAvailabilityDialog), findsNothing);
      expect(updateCalled, isFalse);
    });

    testWidgets(
      'tapping Mark unavailable invokes callback with false and pops dialog',
      (tester) async {
        bool? passedAvailability;
        await tester.pumpWidget(
          buildDialogHost(
            item: availableItem,
            onUpdateAvailability: (avail) async {
              passedAvailability = avail;
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey('change-availability-submit-button')),
        );
        await tester.pumpAndSettle();

        expect(passedAvailability, isFalse);
        expect(find.byType(ChangeAvailabilityDialog), findsNothing);
      },
    );

    testWidgets(
      'tapping Mark available invokes callback with true and pops dialog',
      (tester) async {
        bool? passedAvailability;
        await tester.pumpWidget(
          buildDialogHost(
            item: unavailableItem,
            onUpdateAvailability: (avail) async {
              passedAvailability = avail;
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey('change-availability-submit-button')),
        );
        await tester.pumpAndSettle();

        expect(passedAvailability, isTrue);
        expect(find.byType(ChangeAvailabilityDialog), findsNothing);
      },
    );

    testWidgets('shows loading indicator while update is in progress', (
      tester,
    ) async {
      final completer = Completer<void>();
      await tester.pumpWidget(
        buildDialogHost(
          item: availableItem,
          onUpdateAvailability: (_) => completer.future,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('change-availability-submit-button')),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();
      expect(find.byType(ChangeAvailabilityDialog), findsNothing);
    });

    testWidgets(
      'on update error shows error toast and does not dismiss dialog',
      (tester) async {
        await tester.pumpWidget(
          buildDialogHost(
            item: availableItem,
            onUpdateAvailability: (_) async => throw Exception('Network error'),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey('change-availability-submit-button')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ChangeAvailabilityDialog), findsOneWidget);
        expect(
          find.text(
            'Failed to update availability for Gamcheon Samgyupsal Rice Bowl',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
