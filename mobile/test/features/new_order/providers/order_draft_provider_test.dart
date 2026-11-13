import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/models/brand_models.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/data/models/order_draft_models.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';
import 'package:mobile/features/new_order/providers/order_draft_provider.dart';

const _item = MenuItem(
  id: 'meal',
  name: 'Meal',
  description: '',
  pricesCentavos: {MenuChannel.dineIn: 10000},
);
const _line = CartLine(id: 'line', item: _item, quantity: 1);

void main() {
  test('Request edits rotate the ID while identical retries keep it', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ids = container.read(clientOrderIdProvider.notifier);
    String request({
      String brand = 'gc',
      MenuChannel channel = MenuChannel.dineIn,
      String reference = 'Table 1',
      int quantity = 1,
      String? store,
    }) => ids.forRequest(
      brandId: brand,
      channel: channel,
      reference: reference,
      merchantStoreReference: store,
      lines: [_line.copyWith(quantity: quantity)],
    );
    var id = request();
    expect(request(reference: ' Table 1 '), id);
    for (final next in <String Function()>[
      () => request(quantity: 2),
      () => request(reference: 'Table 2'),
      () => request(brand: 'kk'),
      () => request(channel: MenuChannel.takeaway),
      () => request(channel: MenuChannel.grabFood, store: 'KK Grab'),
      () => request(channel: MenuChannel.grabFood, store: 'GC Grab'),
    ]) {
      final changed = next();
      expect(changed, isNot(id));
      expect(next(), changed);
      id = changed;
    }
  });

  test('Clearing the cart resets its draft and ID even for an identical next order', () {
    final container = ProviderContainer(
      overrides: [
        assignedBrandsProvider.overrideWithValue([
          const AssignedBrand(id: 'gc', code: 'GC', name: 'Gamcheon'),
        ]),
      ],
    );
    addTearDown(container.dispose);
    final cart = container.read(cartProvider.notifier);
    cart.add(_item);
    final ids = container.read(clientOrderIdProvider.notifier);
    final original = ids.forRequest(
      brandId: 'gc',
      channel: MenuChannel.dineIn,
      lines: container.read(cartProvider),
      reference: 'Table 1',
    );
    container
        .read(activeOrderDraftProvider.notifier)
        .set(
          OrderDraft(
            orderId: original,
            orderCode: 'GC-1',
            orderNumber: 1,
            brandId: 'gc',
            channel: 'DINE_IN',
            status: 'DRAFT',
          ),
        );
    cart.clear();
    expect(container.read(activeOrderDraftProvider), isNull);
    cart.add(_item);
    final next = ids.forRequest(
      brandId: 'gc',
      channel: MenuChannel.dineIn,
      lines: container.read(cartProvider),
      reference: 'Table 1',
    );
    expect(next, isNot(original));
  });
}
