import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/models/brand_models.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/presentation/pages/mobile_order_flow_screen.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';
import 'package:mobile/features/new_order/providers/order_draft_provider.dart';
import 'package:mobile/features/order_entry/data/repositories/order_entry_repository.dart';

class FakeActiveBrandNotifier extends ActiveBrandNotifier {
  FakeActiveBrandNotifier(this._brand);
  final AssignedBrand _brand;
  @override
  AssignedBrand build() => _brand;
}

class MockOrderEntryRepository implements OrderEntryRepository {
  MockOrderEntryRepository({
    this.shouldFailCreate = false,
    this.createErrorMessage = 'Item stockout during draft creation',
  });

  final bool shouldFailCreate;
  final String createErrorMessage;

  int createCallCount = 0;
  int confirmCallCount = 0;
  Map<String, dynamic>? lastCreatePayload;
  Map<String, dynamic>? lastConfirmPayload;

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
    createCallCount++;
    lastCreatePayload = {
      'brandId': brandId,
      'orderId': orderId,
      'channel': channel,
      'reference': reference,
      'linesCount': lines.length,
    };

    if (shouldFailCreate) {
      throw DioException(
        requestOptions: RequestOptions(path: '/brands/$brandId/orders'),
        response: Response(
          requestOptions: RequestOptions(path: '/brands/$brandId/orders'),
          statusCode: 400,
          data: {'message': createErrorMessage},
        ),
      );
    }

    return {
      'order_id': orderId,
      'order_code': 'GC-00042',
      'order_number': 42,
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
    confirmCallCount++;
    lastConfirmPayload = {
      'brandId': brandId,
      'orderId': orderId,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
    };

    return {
      'order_id': orderId,
      'order_code': 'GC-00042',
      'order_number': 42,
      'brand_id': brandId,
      'status': 'CONFIRMED',
      'payment_status': paymentStatus ?? 'UNPAID',
      'kitchen_tickets_order': {'ticket_number': 'T-042', 'status': 'QUEUED'},
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
    return {'order_id': orderId, 'valid': true};
  }

  @override
  Future<Map<String, dynamic>> cancelDraftOrder({
    required String brandId,
    required String orderId,
    required String cancellationReason,
  }) async {
    return {'order_id': orderId, 'status': 'CANCELLED'};
  }
}

void main() {
  final sampleBrand = AssignedBrand(
    id: '44444444-4444-4444-8444-444444444444',
    code: 'GC',
    name: 'Gamcheon',
  );

  final sampleItem = MenuItem(
    id: '22222222-2222-4222-8222-222222222222',
    name: 'Gamcheon Samgyupsal Rice Bowl',
    description: 'Pork belly over rice',
    pricesCentavos: const {MenuChannel.dineIn: 26000},
  );

  Widget createSubject(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: MobileOrderFlowScreen(initialStep: 3)),
    );
  }

  testWidgets('Step 3 prevents submitting another provider’s items', (
    tester,
  ) async {
    final mockRepo = MockOrderEntryRepository();
    final container = ProviderContainer(
      overrides: [
        orderEntryRepositoryProvider.overrideWithValue(mockRepo),
        assignedBrandsProvider.overrideWithValue([sampleBrand]),
      ],
    );
    addTearDown(container.dispose);
    container.read(activeBrandProvider.notifier).select(sampleBrand);
    container.read(cartProvider.notifier).add(sampleItem);
    container
        .read(activeBrandProvider.notifier)
        .select(
          const AssignedBrand(
            id: '55555555-5555-4555-8555-555555555555',
            code: 'KK',
            name: 'King Kungs Cafe',
          ),
        );
    container.read(menuChannelProvider.notifier).select(MenuChannel.takeaway);

    await tester.pumpWidget(createSubject(container));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review order'));
    await tester.pumpAndSettle();

    expect(mockRepo.createCallCount, 0);
    expect(
      find.textContaining('Each order must contain items from one provider.'),
      findsOneWidget,
    );
    expect(container.read(cartProvider).single.brandName, sampleBrand.name);
  });

  testWidgets(
    'Step 3 requires table for Dine-in and does not call API when blank',
    (tester) async {
      final mockRepo = MockOrderEntryRepository();
      final container = ProviderContainer(
        overrides: [
          orderEntryRepositoryProvider.overrideWithValue(mockRepo),
          activeBrandProvider.overrideWith(
            () => FakeActiveBrandNotifier(sampleBrand),
          ),
        ],
      );

      container.read(cartProvider.notifier).addConfigured(sampleItem, {}, 1);
      container.read(menuChannelProvider.notifier).select(MenuChannel.dineIn);

      await tester.pumpWidget(createSubject(container));
      await tester.pumpAndSettle();

      // Tap "Review order" with empty table field
      await tester.tap(find.text('Review order'));
      await tester.pumpAndSettle();

      expect(mockRepo.createCallCount, 0);
      expect(
        find.text('Enter the table before reviewing a dine-in order.'),
        findsOneWidget,
      );
      expect(find.text('Table is required.'), findsOneWidget);
    },
  );

  testWidgets(
    'Step 3 creates order draft via API when valid and advances to Step 4',
    (tester) async {
      final mockRepo = MockOrderEntryRepository();
      final container = ProviderContainer(
        overrides: [
          orderEntryRepositoryProvider.overrideWithValue(mockRepo),
          activeBrandProvider.overrideWith(
            () => FakeActiveBrandNotifier(sampleBrand),
          ),
        ],
      );

      container.read(cartProvider.notifier).addConfigured(sampleItem, {}, 2);
      container.read(menuChannelProvider.notifier).select(MenuChannel.dineIn);

      await tester.pumpWidget(createSubject(container));
      await tester.pumpAndSettle();

      // Enter table number
      await tester.enterText(find.byType(TextField), 'Table 12');
      await tester.pumpAndSettle();

      // Tap "Review order"
      await tester.tap(find.text('Review order'));
      await tester.pumpAndSettle();

      // Verify draft creation API call
      expect(mockRepo.createCallCount, 1);
      expect(mockRepo.lastCreatePayload?['reference'], 'Table 12');
      expect(
        mockRepo.lastCreatePayload?['brandId'],
        '44444444-4444-4444-8444-444444444444',
      );

      // Verify activeOrderDraftProvider has the response
      final draft = container.read(activeOrderDraftProvider);
      expect(draft, isNotNull);
      expect(draft?.orderCode, 'GC-00042');
      expect(draft?.tableReference, 'Table 12');

      // Verify navigated to Step 4 "Review order"
      expect(find.text('Review order'), findsOneWidget);
      expect(find.text('Table 12'), findsOneWidget);
      expect(find.text('Confirm and send'), findsOneWidget);
    },
  );

  testWidgets('Step 3 displays API error banner when draft creation fails', (
    tester,
  ) async {
    final mockRepo = MockOrderEntryRepository(
      shouldFailCreate: true,
      createErrorMessage: 'Menu item is unavailable on this channel.',
    );
    final container = ProviderContainer(
      overrides: [
        orderEntryRepositoryProvider.overrideWithValue(mockRepo),
        activeBrandProvider.overrideWith(
          () => FakeActiveBrandNotifier(sampleBrand),
        ),
      ],
    );

    container.read(cartProvider.notifier).addConfigured(sampleItem, {}, 1);
    container.read(menuChannelProvider.notifier).select(MenuChannel.dineIn);

    await tester.pumpWidget(createSubject(container));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Table 5');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Review order'));
    await tester.pumpAndSettle();

    expect(mockRepo.createCallCount, 1);
    // Stays on Step 3 and shows server error message
    expect(
      find.text('Menu item is unavailable on this channel.'),
      findsOneWidget,
    );
    expect(find.text('Review order'), findsOneWidget);
  });

  testWidgets(
    'Full flow: Step 3 creates draft -> Step 4 confirms order -> Step 5 shows real kitchen ticket',
    (tester) async {
      final mockRepo = MockOrderEntryRepository();
      final container = ProviderContainer(
        overrides: [
          orderEntryRepositoryProvider.overrideWithValue(mockRepo),
          activeBrandProvider.overrideWith(
            () => FakeActiveBrandNotifier(sampleBrand),
          ),
        ],
      );

      container.read(cartProvider.notifier).addConfigured(sampleItem, {}, 1);
      container.read(menuChannelProvider.notifier).select(MenuChannel.dineIn);

      await tester.pumpWidget(createSubject(container));
      await tester.pumpAndSettle();

      // Step 3 -> Step 4
      await tester.enterText(find.byType(TextField), 'Table 9');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review order'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm and send'), findsOneWidget);

      // Step 4 -> Step 5
      await tester.tap(find.text('Confirm and send'));
      await tester.pumpAndSettle();

      expect(mockRepo.confirmCallCount, 1);

      // Step 5 Confirmation View
      expect(find.text('Kitchen ticket confirmed'), findsOneWidget);
      expect(find.text('T-042'), findsOneWidget);
      expect(find.text('GC-00042'), findsOneWidget);
      expect(find.text('Table 9'), findsOneWidget);
      expect(find.text('New order'), findsOneWidget);

      // Tapping New order clears cart and draft
      await tester.tap(find.text('New order'));
      await tester.pumpAndSettle();

      expect(container.read(cartProvider), isEmpty);
      expect(container.read(activeOrderDraftProvider), isNull);
    },
  );
}
