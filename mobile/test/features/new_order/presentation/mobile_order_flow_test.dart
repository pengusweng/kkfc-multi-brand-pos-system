import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/presentation/pages/mobile_order_flow_screen.dart';
import 'package:mobile/features/new_order/presentation/widgets/order_flow/cart_item_card.dart';
import 'package:mobile/features/new_order/presentation/widgets/order_flow/order_flow_stepper.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

void main() {
  final sampleItem = MenuItem(
    id: 'gamcheon-samgyupsal',
    name: 'Gamcheon Samgyupsal Rice Bowl',
    description:
        'Thinly sliced pork belly marinated in house gochujang sweet soy, sesame and scallions over warm rice.',
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
        ],
      ),
      ModifierGroup.addOn(
        id: 'fried-egg',
        name: 'Fried Sunny-Side Egg',
        priceCentavos: 2500,
      ),
    ],
  );

  Widget createSubject(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: MobileOrderFlowScreen(),
      ),
    );
  }

  testWidgets(
    'MobileOrderFlowScreen displays cart matching visual design, steps without rerouting, and controls work',
    (tester) async {
      final container = ProviderContainer();

      // Configure cart with 1 line, quantity 2, matching the screenshot
      container.read(cartProvider.notifier).addConfigured(
        sampleItem,
        {
          'rice-choice': 'garlic-butter-rice',
          'spice-level': 'mild',
          'fried-egg': ModifierGroup.addOnOn,
        },
        2,
      );

      await tester.pumpWidget(createSubject(container));
      await tester.pumpAndSettle();

      // Verify Header & Sub-header
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Current order'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);

      // Verify Stepper
      expect(find.byType(OrderFlowStepper), findsOneWidget);
      expect(find.text('Order'), findsOneWidget); // Active step label

      // Verify Subtitle: "1 line · 2 items · Dine-in"
      expect(find.text('1 line · 2 items · Dine-in'), findsOneWidget);

      // Verify Cart Item Card
      expect(find.text('Gamcheon Samgyupsal Rice Bowl'), findsOneWidget);
      expect(find.text('₱520.00'), findsWidgets); // Line total and order total
      expect(find.text('Gamcheon'), findsOneWidget);
      expect(find.text('₱260.00 each'), findsOneWidget);

      // Verify formatted modifiers: Garlic Butter Rice (+₱15) · Mild (Touch of Sweetness) · Fried Sunny-Side Egg (+₱25)
      expect(
        find.text(
          'Garlic Butter Rice (+₱15) · Mild (Touch of Sweetness) · Fried Sunny-Side Egg (+₱25)',
        ),
        findsOneWidget,
      );

      // Verify controls
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CartItemCard),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);

      // Verify Subtotal & Total
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);

      // Verify Continue Button
      expect(find.text('Continue to order details'), findsOneWidget);

      // Test stepping to Step 3 without rerouting!
      await tester.tap(find.text('Continue to order details'));
      await tester.pumpAndSettle();

      // Title should now be "Order details"
      expect(find.text('Order details'), findsOneWidget);
      expect(find.text('Order Channel'), findsOneWidget);
      expect(find.text('Table reference'), findsOneWidget);
      expect(find.text('Continue to payment'), findsOneWidget);

      // Test stepping back to Step 2 using Back button
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      // Back on Step 2 "Current order"
      expect(find.text('Current order'), findsOneWidget);
      expect(find.text('Continue to order details'), findsOneWidget);

      // Test Stepper tap navigation: tap step 3 directly
      await tester.tap(find.text('Continue to order details'));
      await tester.pumpAndSettle();
      expect(find.text('Order details'), findsOneWidget);

      // Tap Step 2 on stepper
      await tester.tap(find.byKey(const ValueKey('step-2')));
      await tester.pumpAndSettle();
      expect(find.text('Current order'), findsOneWidget);

      // Test Quantity increment: tap [+]
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(container.read(cartCountProvider), 3);
      expect(
        find.descendant(
          of: find.byType(CartItemCard),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );
      expect(find.text('₱780.00'), findsWidgets); // 260 * 3
    },
  );
}
