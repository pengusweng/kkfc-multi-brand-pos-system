import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/features/auth/providers/auth_profile_provider.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/data/models/order_draft_models.dart';
import 'package:mobile/features/new_order/presentation/widgets/order_flow/review_order_step_view.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';
import 'package:mobile/features/new_order/providers/order_draft_provider.dart';
import 'package:mobile/features/orders/cancel/data/models/cancel_order_outcome.dart';
import 'package:mobile/features/orders/cancel/data/repositories/cancel_order_repository.dart';

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
  testWidgets(
    'ReviewOrderStepView (Step 4): Shows "Cancel order" below "Confirm and send", opens CancelOrderScreen, Keep order returns, and cancel completes',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      var confirmCalled = false;
      var cancelOrderCalled = false;

      final fakeRepo = _FakeCancelRepository(
        const CancelOrderAccepted(
          CancelOrderOutcome(
            orderId: 'mock-order-id',
            status: 'CANCELLED',
            orderCode: 'ORD-2026-1105-017',
            cancellationReason: 'Duplicate entry at counter',
          ),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          cancelOrderRepositoryProvider.overrideWithValue(fakeRepo),
          authenticatedBrandIdProvider.overrideWith((ref) async => 'brand-1'),
        ],
      );
      container.read(activeOrderDraftProvider.notifier).set(
            const OrderDraft(
              orderId: 'mock-order-id',
              orderCode: 'ORD-2026-1105-017',
              orderNumber: 17,
              brandId: 'brand-1',
              channel: 'DINE_IN',
              status: 'DRAFT',
              ticketNumber: 'T-017',
            ),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: counterTheme,
            home: Scaffold(
              body: ReviewOrderStepView(
                onConfirm: () => confirmCalled = true,
                onCancelOrder: () => cancelOrderCalled = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Step 4 shows "Confirm and send" and "Cancel order" below it
      expect(find.text('Confirm and send'), findsOneWidget);
      expect(find.text('Cancel order'), findsOneWidget);

      // 2. Tap "Cancel order" in Step 4
      await tester.tap(find.text('Cancel order'));
      await tester.pumpAndSettle();

      // 3. Verify CancelOrderScreen is opened
      expect(find.text('Cancel order'), findsNWidgets(2)); // Title & button
      expect(find.text('ORD-2026-1105-017'), findsWidgets);
      expect(find.text('T-017'), findsWidgets);
      expect(find.text('Queued · preparation not started'), findsOneWidget);
      expect(find.text('Reason for cancelling'), findsOneWidget);
      expect(find.byKey(const ValueKey('keep-order-button')), findsOneWidget);

      // 4. Tap "Keep order" to return to Step 4
      await tester.tap(find.byKey(const ValueKey('keep-order-button')));
      await tester.pumpAndSettle();

      // Back on Step 4
      expect(find.text('Confirm and send'), findsOneWidget);
      expect(find.text('Cancel order'), findsOneWidget);

      // 5. Tap "Cancel order" again
      await tester.tap(find.text('Cancel order'));
      await tester.pumpAndSettle();

      // Enter reason and tap Cancel order
      await tester.enterText(
        find.byType(TextField),
        'Duplicate entry at counter',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('submit-cancel-order-button')));
      await tester.pumpAndSettle();

      // 6. Verify "Order cancelled" success screen
      expect(find.text('Order cancelled'), findsOneWidget);
      expect(find.byKey(const ValueKey('back-to-menu-button')), findsOneWidget);
      expect(fakeRepo.calls, hasLength(1));
      expect(fakeRepo.calls.single.reason, 'Duplicate entry at counter');

      // 7. Tap "Back to menu"
      await tester.tap(find.byKey(const ValueKey('back-to-menu-button')));
      await tester.pumpAndSettle();

      expect(cancelOrderCalled, isTrue);
      expect(confirmCalled, isFalse);
      expect(container.read(activeOrderDraftProvider), isNull);
    },
  );
}
