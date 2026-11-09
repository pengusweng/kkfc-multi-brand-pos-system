import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/presentation/pages/mobile_order_flow_screen.dart';
import 'package:mobile/features/new_order/presentation/widgets/order_flow/cart_item_card.dart';
import 'package:mobile/features/new_order/presentation/widgets/order_flow/order_flow_stepper.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';
import 'package:mobile/features/order_entry/data/repositories/order_entry_repository.dart';

class FakeOrderEntryRepository implements OrderEntryRepository {
  @override
  Future<Map<String, dynamic>> createOrder({
    required String brandId,
    required String orderId,
    required MenuChannel channel,
    required List<CartLine> lines,
    String? reference,
    String? merchantStoreReference,
    String? notes,
  }) async {
    return {
      'order_id': orderId,
      'order_code': 'ORD-2026-1105-017',
      'order_number': 17,
      'brand_id': brandId,
      'order_channel': channel.apiValue,
      'table_reference': reference,
      'status': 'DRAFT',
      'payment_status': 'UNPAID',
    };
  }

  @override
  Future<Map<String, dynamic>> confirmOrder({
    required String brandId,
    required String orderId,
    String? paymentMethod,
    String? paymentStatus,
    String? paymentReference,
  }) async {
    return {
      'order_id': orderId,
      'order_code': 'ORD-2026-1105-017',
      'order_number': 17,
      'brand_id': brandId,
      'status': 'CONFIRMED',
      'payment_status': paymentStatus ?? 'UNPAID',
      'kitchen_tickets_order': {
        'ticket_number': 'T-017',
        'status': 'QUEUED',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> verifyOrder({
    required String brandId,
    required String orderId,
    String? paymentMethod,
    String? paymentStatus,
    String? paymentReference,
  }) async {
    return {
      'order_id': orderId,
      'valid': true,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
    };
  }

  @override
  Future<Map<String, dynamic>> cancelDraftOrder({
    required String brandId,
    required String orderId,
    required String cancellationReason,
  }) async {
    return {
      'order_id': orderId,
      'status': 'CANCELLED',
      'cancellation_reason': cancellationReason,
    };
  }
}

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
      final container = ProviderContainer(
        overrides: [
          orderEntryRepositoryProvider.overrideWithValue(
            FakeOrderEntryRepository(),
          ),
        ],
      );

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
      expect(find.text('Channel'), findsOneWidget);
      expect(find.text('Dine-in'), findsOneWidget);
      expect(find.text('Takeaway'), findsOneWidget);
      expect(find.text('GrabFood'), findsOneWidget);
      expect(find.text('foodpanda'), findsOneWidget);
      expect(find.text('Table'), findsOneWidget);
      expect(find.text('For example: Table 4'), findsOneWidget);
      expect(find.text('Payment status '), findsOneWidget);
      expect(find.text('Unpaid'), findsOneWidget);
      expect(
        find.text(
          'Guests pay after eating. Sending does not wait for payment.',
        ),
        findsOneWidget,
      );
      expect(find.text('Review order'), findsOneWidget);

      // Test validation: tapping "Review order" without table triggers error
      await tester.tap(find.text('Review order'));
      await tester.pumpAndSettle();

      expect(
        find.text('Enter the table before reviewing a dine-in order.'),
        findsOneWidget,
      );
      expect(find.text('Table is required.'), findsOneWidget);

      // Enter table reference to satisfy validation
      await tester.enterText(find.byType(TextField), 'Table 4');
      await tester.pumpAndSettle();

      // Error banner should be cleared
      expect(
        find.text('Enter the table before reviewing a dine-in order.'),
        findsNothing,
      );

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

      // Proceed: Step 2 -> Step 3 (Order details)
      await tester.tap(find.text('Continue to order details'));
      await tester.pumpAndSettle();

      // Enter table reference
      await tester.enterText(find.byType(TextField), 'Table 7');
      await tester.pumpAndSettle();

      // Proceed: Step 3 -> Step 4 (Review order)
      await tester.tap(find.text('Review order'));
      await tester.pumpAndSettle();

      // Verify Step 4 "Review order"
      expect(find.text('Review order'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget); // active stepper label
      expect(
        find.text('Not sent yet. Please review carefully before confirming.'),
        findsOneWidget,
      );
      expect(find.text('Table 7'), findsOneWidget);
      expect(find.text('1 line · 3 items'), findsOneWidget);
      expect(find.text('3×'), findsOneWidget);
      expect(find.text('Confirm and send'), findsOneWidget);
      expect(find.text('Cancel order'), findsOneWidget);

      // Proceed: Step 4 -> Step 5 (Kitchen ticket confirmed)
      await tester.tap(find.text('Confirm and send'));
      await tester.pumpAndSettle();

      // Verify Step 5 "Sent"
      expect(find.text('Sent'), findsOneWidget);
      expect(find.text('Kitchen ticket confirmed'), findsOneWidget);
      expect(find.text('Kitchen ticket'), findsOneWidget);
      expect(find.text('T-017'), findsOneWidget);
      expect(find.text('ORD-2026-1105-017'), findsOneWidget);
      expect(find.text('New order'), findsOneWidget);
      expect(find.text('Cancel order'), findsNothing);
    },
  );
}
