import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/presentation/widgets/item_customization_dialog.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

void main() {
  final testItem = MenuItem(
    id: 'gamcheon-samgyupsal',
    name: 'Gamcheon Samgyupsal Rice Bowl',
    description: 'Thinly sliced pork belly marinated in house gochujang sweet soy, sesame and scallions over warm rice.',
    pricesCentavos: const {
      MenuChannel.dineIn: 22000,
      MenuChannel.takeaway: 22000,
    },
    modifierGroups: [
      const ModifierGroup(
        id: 'rice-choice',
        title: 'Rice Choice',
        defaultOptionId: 'steamed-white-rice',
        options: [
          ModifierOption(
            id: 'steamed-white-rice',
            label: 'Steamed White Rice',
            priceDeltaCentavos: 0,
          ),
          ModifierOption(
            id: 'garlic-butter-rice',
            label: 'Garlic Butter Rice',
            priceDeltaCentavos: 1500,
          ),
        ],
      ),
      const ModifierGroup(
        id: 'spice-level',
        title: 'Spice Level',
        defaultOptionId: 'mild',
        options: [
          ModifierOption(
            id: 'mild',
            label: 'Mild (Touch of Sweetness)',
            priceDeltaCentavos: 0,
          ),
          ModifierOption(
            id: 'medium',
            label: 'Medium Traditional',
            priceDeltaCentavos: 0,
          ),
          ModifierOption(
            id: 'spicy-fire-garlic',
            label: 'Spicy Fire Garlic',
            priceDeltaCentavos: 1000,
          ),
        ],
      ),
      ModifierGroup.addOn(
        id: 'fried-egg',
        name: 'Fried Sunny-Side Egg',
        priceCentavos: 2500,
      ),
      ModifierGroup.addOn(
        id: 'house-kimchi',
        name: 'House Kimchi Portion (60g)',
        priceCentavos: 3000,
      ),
    ],
  );

  testWidgets(
    'ItemCustomizationDialog displays all options, calculates price, and adds to cart',
    (tester) async {
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showItemCustomizationDialog(
                        context,
                        item: testItem,
                        channel: MenuChannel.dineIn,
                        brandName: 'Gamcheon',
                      );
                    },
                    child: const Text('Open Dialog'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Check header
      expect(find.text('Gamcheon Samgyupsal Rice Bowl'), findsOneWidget);
      expect(find.text('Gamcheon · Dine-in price · ₱220.00'), findsOneWidget);

      // Check description
      expect(
        find.textContaining('Thinly sliced pork belly marinated'),
        findsOneWidget,
      );

      // Check Badges
      expect(
        find.text('Chosen'),
        findsNWidgets(2),
      ); // Rice Choice & Spice Level
      expect(find.text('Optional'), findsOneWidget); // Add-Ons

      // Check Radio options
      expect(find.text('Steamed White Rice'), findsOneWidget);
      expect(find.text('Garlic Butter Rice'), findsOneWidget);
      expect(find.text('+₱15.00'), findsOneWidget);

      expect(find.text('Mild (Touch of Sweetness)'), findsOneWidget);
      expect(find.text('Medium Traditional'), findsOneWidget);
      expect(find.text('Spicy Fire Garlic'), findsOneWidget);
      expect(find.text('+₱10.00'), findsOneWidget);

      // Check Add-ons
      expect(find.text('Fried Sunny-Side Egg'), findsOneWidget);
      expect(find.text('+₱25.00'), findsOneWidget);
      expect(find.text('House Kimchi Portion (60g)'), findsOneWidget);
      expect(find.text('+₱30.00'), findsOneWidget);

      // Base price at the start is ₱220.00
      expect(find.text('₱220.00'), findsWidgets);

      // Select Garlic Butter Rice (+₱15.00)
      await tester.ensureVisible(find.text('Garlic Butter Rice'));
      await tester.tap(find.text('Garlic Butter Rice'));
      await tester.pumpAndSettle();

      // Price should now be 220 + 15 = ₱235.00
      expect(find.text('₱235.00'), findsOneWidget);

      // Select Fried Sunny-Side Egg (+₱25.00)
      await tester.ensureVisible(find.text('Fried Sunny-Side Egg'));
      await tester.tap(find.text('Fried Sunny-Side Egg'));
      await tester.pumpAndSettle();

      // Price should now be 235 + 25 = ₱260.00
      expect(find.text('₱260.00'), findsOneWidget);

      // Increment quantity to 2
      await tester.ensureVisible(find.byIcon(Icons.add));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Price should now be 260 * 2 = ₱520.00
      expect(find.text('₱520.00'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Enter kitchen note
      final kitchenNoteFinder = find.byKey(
        const ValueKey('customize-kitchen-note-field'),
      );
      await tester.ensureVisible(kitchenNoteFinder);
      await tester.enterText(kitchenNoteFinder, 'Extra crispy pork please');
      await tester.pumpAndSettle();

      // Tap "Add to order"
      await tester.ensureVisible(find.text('Add to order'));
      await tester.tap(find.text('Add to order'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text('Gamcheon Samgyupsal Rice Bowl'), findsNothing);

      // Cart provider should have 1 line with the configured item
      final cart = container.read(cartProvider);
      expect(cart.length, 1);
      expect(cart.first.quantity, 2);
      expect(cart.first.selections['rice-choice'], 'garlic-butter-rice');
      expect(cart.first.selections['fried-egg'], ModifierGroup.addOnOn);
      expect(cart.first.kitchenNote, 'Extra crispy pork please');
      expect(cart.first.totalCentavos(MenuChannel.dineIn), 52000);
    },
  );

  testWidgets(
    'ItemCustomizationDialog shows when item has no add-ons, hiding the add-on section while keeping quantity and notes',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const simpleItem = MenuItem(
        id: 'simple-item',
        name: 'Simple Drink',
        description: 'Fresh brewed iced tea',
        pricesCentavos: {MenuChannel.dineIn: 7500, MenuChannel.takeaway: 7500},
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showItemCustomizationDialog(
                    context,
                    item: simpleItem,
                    channel: MenuChannel.dineIn,
                    brandName: 'Gamcheon',
                  ),
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Dialog shows title, brand, and description
      expect(find.text('Simple Drink'), findsOneWidget);
      expect(find.textContaining('Gamcheon'), findsOneWidget);
      expect(find.text('Fresh brewed iced tea'), findsOneWidget);

      // Add-ons section and radio modifier sections should NOT be present
      expect(find.text('Add-Ons'), findsNothing);
      expect(find.text('Optional'), findsNothing);
      expect(find.text('Rice Choice'), findsNothing);

      // Quantity stepper and Kitchen Note ARE present
      expect(find.text('Quantity'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('customize-quantity-field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('customize-kitchen-note-field')),
        findsOneWidget,
      );

      // Base price is shown
      expect(find.text('₱75.00'), findsWidgets);

      // Increment quantity
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
      expect(find.text('₱150.00'), findsOneWidget);

      // Enter kitchen note
      await tester.enterText(
        find.byKey(const ValueKey('customize-kitchen-note-field')),
        'Less ice',
      );
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Add to order'));
      await tester.pumpAndSettle();

      // Dialog dismissed
      expect(find.text('Simple Drink'), findsNothing);

      // Cart provider has 1 line with quantity 2 and kitchen note
      final cart = container.read(cartProvider);
      expect(cart.length, 1);
      expect(cart.first.item.id, 'simple-item');
      expect(cart.first.quantity, 2);
      expect(cart.first.kitchenNote, 'Less ice');
      expect(cart.first.totalCentavos(MenuChannel.dineIn), 15000);
    },
  );

  testWidgets(
    'ItemCustomizationDialog allows user to type desired quantity directly into quantity field',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showItemCustomizationDialog(
                    context,
                    item: testItem,
                    channel: MenuChannel.dineIn,
                    brandName: 'Gamcheon',
                  ),
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      final quantityField = find.byKey(
        const ValueKey('customize-quantity-field'),
      );
      expect(quantityField, findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('₱220.00'), findsWidgets);

      // Type "5" into the quantity field
      await tester.enterText(quantityField, '5');
      await tester.pumpAndSettle();

      // Total price should update immediately to ₱1,100.00 (220 * 5)
      expect(find.text('₱1,100.00'), findsOneWidget);

      // Submit
      await tester.tap(find.text('Add to order'));
      await tester.pumpAndSettle();

      final cart = container.read(cartProvider);
      expect(cart.length, 1);
      expect(cart.first.quantity, 5);
      expect(cart.first.totalCentavos(MenuChannel.dineIn), 110000);
    },
  );

  testWidgets(
    'ItemCustomizationDialog clamps quantity to minimum 1 when typing 0 upon submission',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showItemCustomizationDialog(
                    context,
                    item: testItem,
                    channel: MenuChannel.dineIn,
                    brandName: 'Gamcheon',
                  ),
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      final quantityField = find.byKey(
        const ValueKey('customize-quantity-field'),
      );
      await tester.enterText(quantityField, '0');
      await tester.pumpAndSettle();

      // Tap submit: should clamp to minimum 1
      await tester.tap(find.text('Add to order'));
      await tester.pumpAndSettle();

      final cart = container.read(cartProvider);
      expect(cart.length, 1);
      expect(cart.first.quantity, 1);
      expect(cart.first.totalCentavos(MenuChannel.dineIn), 22000);
    },
  );

  testWidgets(
    'Holding stepper button continually increases and decreases quantity',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showItemCustomizationDialog(
                    context,
                    item: testItem,
                    channel: MenuChannel.dineIn,
                    brandName: 'Gamcheon',
                  ),
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      final incFinder = find.byKey(
        const ValueKey('customize-quantity-increment'),
      );
      final decFinder = find.byKey(
        const ValueKey('customize-quantity-decrement'),
      );

      await tester.ensureVisible(incFinder);
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);

      // 1. Hold increment button
      final incGesture = await tester.startGesture(tester.getCenter(incFinder));
      await tester.pump();
      // First step on tap down -> 2
      expect(find.text('2'), findsOneWidget);

      // Advance by hold delay (350ms)
      await tester.pump(const Duration(milliseconds: 350));
      // First repeat tick (+80ms) -> 3
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.text('3'), findsOneWidget);

      // Second repeat tick (+80ms) -> 4
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.text('4'), findsOneWidget);

      // Release hold
      await incGesture.up();
      await tester.pumpAndSettle();

      // Total price is now 220 * 4 = ₱880.00
      expect(find.text('₱880.00'), findsOneWidget);

      // 2. Hold decrement button
      final decGesture = await tester.startGesture(tester.getCenter(decFinder));
      await tester.pump();
      // First step on tap down -> 3
      expect(find.text('3'), findsOneWidget);

      // Advance by hold delay (350ms)
      await tester.pump(const Duration(milliseconds: 350));
      // First repeat tick (+80ms) -> 2
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.text('2'), findsOneWidget);

      // Second repeat tick (+80ms) -> 1
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.text('1'), findsOneWidget);

      // Third repeat tick (+80ms) -> cannot go below 1, remains 1
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.text('1'), findsOneWidget);

      // Release hold
      await decGesture.up();
      await tester.pumpAndSettle();

      expect(find.text('₱220.00'), findsWidgets);
    },
  );
}
