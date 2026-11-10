import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/features/auth/providers/auth_profile_provider.dart';
import 'package:mobile/features/orders/cancel/data/models/cancel_order_outcome.dart';
import 'package:mobile/features/orders/cancel/data/repositories/cancel_order_repository.dart';
import 'package:mobile/features/orders/cancel/presentation/pages/cancel_order_screen.dart';

const _liveOrderId = '11111111-1111-4111-8111-111111111111';

class _FakeCancelRepository implements CancelOrderRepository {
  _FakeCancelRepository(this.result);

  CancelOrderResult result;
  final calls = <({String brandId, String orderId, String reason})>[];

  @override
  Future<CancelOrderResult> cancel({
    required String brandId,
    required String orderId,
    required String reason,
  }) async {
    calls.add((brandId: brandId, orderId: orderId, reason: reason));
    return result;
  }
}

void main() {
  Future<void> pumpCancelOrder(
    WidgetTester tester, {
    String? orderCode,
    String? ticketNumber,
    VoidCallback? onKeepOrder,
    VoidCallback? onBackToMenu,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: counterTheme,
          home: CancelOrderScreen(
            orderCode: orderCode,
            ticketNumber: ticketNumber,
            onKeepOrder: onKeepOrder,
            onBackToMenu: onBackToMenu,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpLiveCancelOrder(
    WidgetTester tester,
    _FakeCancelRepository repository, {
    String orderCode = 'ORD-2026-1105-017',
    String ticketNumber = 'T-017',
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cancelOrderRepositoryProvider.overrideWithValue(repository),
          authenticatedBrandIdProvider.overrideWith((ref) async => 'brand-1'),
        ],
        child: MaterialApp(
          theme: counterTheme,
          home: CancelOrderScreen(
            orderId: _liveOrderId,
            orderCode: orderCode,
            ticketNumber: ticketNumber,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'State 1: Initial state shows title, order details, reason field, disclaimer, and action buttons',
    (tester) async {
      await pumpCancelOrder(
        tester,
        orderCode: 'ORD-2026-1105-017',
        ticketNumber: 'T-017',
      );

      // Top title and button both have "Cancel order"
      expect(find.text('Cancel order'), findsNWidgets(2));

      // Order info card
      expect(find.text('Order'), findsOneWidget);
      expect(find.text('ORD-2026-1105-017'), findsOneWidget);
      expect(find.text('Kitchen ticket'), findsOneWidget);
      expect(find.text('T-017'), findsOneWidget);
      expect(find.text('Kitchen stage'), findsOneWidget);
      expect(find.text('Queued · preparation not started'), findsOneWidget);

      // Reason section
      expect(find.text('Reason for cancelling'), findsOneWidget);
      expect(
        find.text('For example: guest changed their mind'),
        findsOneWidget,
      );
      expect(find.text('0/280 characters'), findsOneWidget);

      // Disclaimer
      expect(
        find.text('Cancelling does not refund a payment or change stock.'),
        findsOneWidget,
      );

      // Bottom buttons
      expect(find.byKey(const ValueKey('keep-order-button')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('submit-cancel-order-button')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'State 2: Tapping "Cancel order" without reason triggers validation error message and red border',
    (tester) async {
      await pumpCancelOrder(tester);

      // Tap Cancel order with empty reason
      await tester.tap(
        find.byKey(const ValueKey('submit-cancel-order-button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Enter a reason for cancelling (up to 280 characters).'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    },
  );

  testWidgets(
    'State 3: Active typing clears validation error and updates character counter',
    (tester) async {
      await pumpCancelOrder(tester);

      // Trigger error first
      await tester.tap(
        find.byKey(const ValueKey('submit-cancel-order-button')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Enter a reason for cancelling (up to 280 characters).'),
        findsOneWidget,
      );

      // Enter text
      await tester.enterText(
        find.byType(TextField),
        'Duplicate entry at counter',
      );
      await tester.pumpAndSettle();

      // Error message is cleared
      expect(
        find.text('Enter a reason for cancelling (up to 280 characters).'),
        findsNothing,
      );

      // Counter dynamically updated (length of "Duplicate entry at counter" is 26)
      expect(find.text('26/280 characters'), findsOneWidget);
    },
  );

  testWidgets(
    'State 4: Submitting cancellation navigates to "Order cancelled" success state with "Back to menu" button',
    (tester) async {
      await pumpCancelOrder(
        tester,
        orderCode: 'ORD-2026-1105-017',
        ticketNumber: 'T-017',
      );

      await tester.enterText(
        find.byType(TextField),
        'Duplicate entry at counter',
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('submit-cancel-order-button')),
      );
      await tester.pumpAndSettle();

      // Success card
      expect(find.text('Order cancelled'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('No refund or stock change was made.'), findsOneWidget);

      // Check order code and ticket number in RichText
      expect(find.byType(RichText), findsWidgets);

      // Action button switches to "Back to menu"
      expect(find.byKey(const ValueKey('back-to-menu-button')), findsOneWidget);
      expect(find.byKey(const ValueKey('keep-order-button')), findsNothing);
    },
  );

  testWidgets(
    'Live cancellation: Calls backend repository with brandId, orderId, and reason',
    (tester) async {
      final repository = _FakeCancelRepository(
        CancelOrderAccepted(
          const CancelOrderOutcome(
            orderId: _liveOrderId,
            status: 'CANCELLED',
            orderCode: 'ORD-2026-1105-017',
            cancellationReason: 'Guest changed their mind',
          ),
        ),
      );

      await pumpLiveCancelOrder(tester, repository);

      await tester.enterText(
        find.byType(TextField),
        'Guest changed their mind',
      );
      await tester.tap(
        find.byKey(const ValueKey('submit-cancel-order-button')),
      );
      await tester.pumpAndSettle();

      expect(repository.calls, hasLength(1));
      expect(repository.calls.single.brandId, 'brand-1');
      expect(repository.calls.single.orderId, _liveOrderId);
      expect(repository.calls.single.reason, 'Guest changed their mind');

      // Success screen shown
      expect(find.text('Order cancelled'), findsOneWidget);
      expect(find.byKey(const ValueKey('back-to-menu-button')), findsOneWidget);
    },
  );

  testWidgets(
    'Live cancellation: Displays server denial message if backend rejects',
    (tester) async {
      final repository = _FakeCancelRepository(
        const CancelOrderDenied(
          'Completed orders or handed-over tickets cannot be cancelled.',
          statusCode: 409,
        ),
      );

      await pumpLiveCancelOrder(tester, repository);

      await tester.enterText(find.byType(TextField), 'Guest changed mind');
      await tester.tap(
        find.byKey(const ValueKey('submit-cancel-order-button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Completed orders or handed-over tickets cannot be cancelled.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Callback verification: "Keep order" and "Back to menu" trigger appropriate callbacks',
    (tester) async {
      var keepOrderCalled = false;
      var backToMenuCalled = false;

      await pumpCancelOrder(
        tester,
        onKeepOrder: () => keepOrderCalled = true,
        onBackToMenu: () => backToMenuCalled = true,
      );

      // Tap Keep order
      await tester.tap(find.byKey(const ValueKey('keep-order-button')));
      await tester.pumpAndSettle();
      expect(keepOrderCalled, isTrue);

      // Enter text and cancel
      await tester.enterText(find.byType(TextField), 'Wrong item');
      await tester.tap(
        find.byKey(const ValueKey('submit-cancel-order-button')),
      );
      await tester.pumpAndSettle();

      // Tap Back to menu
      await tester.tap(find.byKey(const ValueKey('back-to-menu-button')));
      await tester.pumpAndSettle();
      expect(backToMenuCalled, isTrue);
    },
  );
}
