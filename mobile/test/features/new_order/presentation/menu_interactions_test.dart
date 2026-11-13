import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/presentation/pages/menu_screen.dart';
import 'package:mobile/features/new_order/presentation/widgets/item_customization_dialog.dart';
import 'package:mobile/features/new_order/presentation/widgets/menu_item_card.dart';
import 'package:mobile/features/new_order/presentation/widgets/menu_states.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

const _meal = MenuItem(
  id: 'meal',
  name: 'Fixture Meal',
  description: 'Grilled chicken',
  pricesCentavos: {MenuChannel.dineIn: 10000},
);

Future<void> _pump(
  WidgetTester tester,
  ProviderContainer container,
  Widget child,
) async {
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(1068, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  container.read(cartProvider.notifier).clear();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: counterTheme,
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'Channel filter uses API availability and refresh picks up restored stock',
    (tester) async {
      var grabAvailable = false;
      var loads = 0;
      final container = ProviderContainer(
        overrides: [
          menuItemsProvider.overrideWith((ref) async {
            loads++;
            return [
              MenuItem.fromApiJson({
                'menu_item_id': 'meal',
                'name': 'Channel Meal',
                'base_price': '100',
                'is_available': true,
                'recipe': {'is_active': true},
                'menuChannels': [
                  {
                    'order_channel': 'GRABFOOD',
                    'price': '120',
                    'is_available': grabAvailable,
                  },
                ],
              }),
            ];
          }),
        ],
      );
      await _pump(tester, container, const MenuScreen());
      await tester.pumpAndSettle();
      container.read(menuChannelProvider.notifier).select(MenuChannel.grabFood);
      await tester.pumpAndSettle();
      expect(find.text('MANUAL OFF'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('unavailable-filter-button')));
      await tester.pumpAndSettle();
      expect(find.text('Channel Meal'), findsNothing);
      expect(find.text('Showing 0 items'), findsOneWidget);
      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      expect(find.text('Include unavailable'), findsOneWidget);
      expect(find.text('Channel Meal'), findsOneWidget);
      expect(find.text('Showing 1 item'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('unavailable-filter-button')));
      await tester.pumpAndSettle();
      container.read(menuChannelProvider.notifier).select(MenuChannel.dineIn);
      await tester.pumpAndSettle();
      expect(find.text('Channel Meal'), findsOneWidget);
      container.read(menuChannelProvider.notifier).select(MenuChannel.grabFood);
      await tester.pumpAndSettle();

      grabAvailable = true;
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(loads, 2);
      expect(find.text('Channel Meal'), findsOneWidget);
      expect(find.text('MANUAL OFF'), findsNothing);
      expect(container.read(hideUnavailableProvider), isTrue);
    },
  );
  for (final availability in MenuAvailability.values) {
    testWidgets(
      'IT-MOB-MENU-001 Given ${availability.name} availability When tapping an item Then only available items enter the cart',
      (tester) async {
        final container = ProviderContainer();
        final item = MenuItem(
          id: _meal.id,
          name: _meal.name,
          description: _meal.description,
          pricesCentavos: _meal.pricesCentavos,
          availability: {MenuChannel.dineIn: availability},
        );
        await _pump(
          tester,
          container,
          Center(
            child: SizedBox(
              width: 300,
              child: MenuItemCard(item: item, channel: MenuChannel.dineIn),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(_meal.name));
        await tester.pumpAndSettle();
        if (availability == MenuAvailability.available) {
          expect(find.byType(ItemCustomizationDialog), findsOneWidget);
          await tester.tap(find.textContaining('Add to order'));
          await tester.pumpAndSettle();
        } else {
          expect(find.byType(ItemCustomizationDialog), findsNothing);
        }
        expect(
          container.read(cartCountProvider),
          availability == MenuAvailability.available ? 1 : 0,
        );
        final badge = switch (availability) {
          MenuAvailability.available => null,
          MenuAvailability.stockout => 'STOCKOUT',
          MenuAvailability.manualOff => 'MANUAL OFF',
          MenuAvailability.inactive => 'INACTIVE',
        };
        if (badge != null) expect(find.text(badge), findsOneWidget);
      },
    );
  }

  testWidgets(
    'IT-MOB-MENU-002 Given a pending menu When data arrives Then replace the skeleton with menu cards',
    (tester) async {
      final pending = Completer<List<MenuItem>>();
      final container = ProviderContainer(
        overrides: [menuItemsProvider.overrideWith((ref) => pending.future)],
      );
      await _pump(tester, container, const MenuScreen());
      await tester.pump();
      expect(find.byType(MenuGridSkeleton), findsOneWidget);
      pending.complete([_meal]);
      await tester.pumpAndSettle();
      expect(find.byType(MenuGridSkeleton), findsNothing);
      expect(find.byType(MenuItemCard), findsOneWidget);
    },
  );

  testWidgets(
    'IT-MOB-MENU-003 Given a failed menu When retrying Then reload and display recovered data',
    (tester) async {
      var loads = 0;
      final container = ProviderContainer(
        overrides: [
          menuItemsProvider.overrideWith((ref) async {
            loads++;
            if (loads == 1) throw StateError('Offline');
            return [_meal];
          }),
        ],
      );
      await _pump(tester, container, const MenuScreen());
      await tester.pumpAndSettle();
      expect(find.text("Couldn't load the menu"), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(loads, 2);
      expect(find.byType(MenuItemCard), findsOneWidget);
    },
  );

  testWidgets(
    'IT-MOB-MENU-004 Given no search matches When clearing search Then restore menu cards and the search field',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          menuItemsProvider.overrideWith((ref) async => [_meal]),
        ],
      );
      await _pump(tester, container, const MenuScreen());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'missing');
      await tester.pumpAndSettle();
      expect(
        find.text('No items in this category or matching search'),
        findsOneWidget,
      );
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(container.read(menuSearchProvider), isEmpty);
      expect(find.byType(MenuItemCard), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        isEmpty,
      );
    },
  );

  testWidgets(
    'IT-MOB-MENU-005 Given an empty catalog When loading completes Then show an empty state without menu cards',
    (tester) async {
      final container = ProviderContainer(
        overrides: [menuItemsProvider.overrideWith((ref) async => [])],
      );
      await _pump(tester, container, const MenuScreen());
      await tester.pumpAndSettle();
      expect(find.byType(MenuMessageCard), findsOneWidget);
      expect(find.byType(MenuItemCard), findsNothing);
    },
  );

  testWidgets(
    'IT-MOB-MENU-006 Given available and unavailable items When tapping Unavailable button Then hide unavailable items',
    (tester) async {
      const availableItem = MenuItem(
        id: 'avail-meal',
        name: 'Available Meal',
        description: 'Fresh and ready',
        pricesCentavos: {MenuChannel.dineIn: 10000},
        availability: {MenuChannel.dineIn: MenuAvailability.available},
      );
      const unavailableItem = MenuItem(
        id: 'unavail-meal',
        name: 'Soldout Meal',
        description: 'Out of stock',
        pricesCentavos: {MenuChannel.dineIn: 10000},
        availability: {MenuChannel.dineIn: MenuAvailability.stockout},
      );
      final container = ProviderContainer(
        overrides: [
          menuItemsProvider.overrideWith(
            (ref) async => [availableItem, unavailableItem],
          ),
        ],
      );
      await _pump(tester, container, const MenuScreen());
      await tester.pumpAndSettle();

      // Initially both items are shown
      expect(find.text('Available Meal'), findsOneWidget);
      expect(find.text('Soldout Meal'), findsOneWidget);
      expect(find.text('Include unavailable'), findsOneWidget);
      final filter = find.byKey(const ValueKey('unavailable-filter-button'));
      expect(
        find.descendant(
          of: filter,
          matching: find.byIcon(Icons.visibility_outlined),
        ),
        findsOneWidget,
      );

      // Tap Unavailable filter button to hide unavailable items
      await tester.tap(find.byKey(const ValueKey('unavailable-filter-button')));
      await tester.pumpAndSettle();

      // Only available item is shown
      expect(find.text('Available Meal'), findsOneWidget);
      expect(find.text('Soldout Meal'), findsNothing);
      expect(find.text('Available only'), findsOneWidget);
      expect(
        find.descendant(
          of: filter,
          matching: find.byIcon(Icons.visibility_off_outlined),
        ),
        findsOneWidget,
      );

      // Tap again to toggle back
      await tester.tap(find.byKey(const ValueKey('unavailable-filter-button')));
      await tester.pumpAndSettle();

      // Both items are visible again
      expect(find.text('Available Meal'), findsOneWidget);
      expect(find.text('Soldout Meal'), findsOneWidget);
      expect(find.text('Include unavailable'), findsOneWidget);
    },
  );
}
