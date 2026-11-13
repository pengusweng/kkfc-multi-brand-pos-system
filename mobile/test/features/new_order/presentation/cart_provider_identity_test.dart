import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/models/brand_models.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/presentation/widgets/cart_panel/cart_panel.dart';
import 'package:mobile/features/new_order/presentation/widgets/order_flow/cart_step_view.dart';
import 'package:mobile/features/new_order/presentation/widgets/order_flow/review_order_step_view.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

const _cafe = AssignedBrand(id: 'kk', code: 'KK', name: 'King Kungs Cafe');
const _gamcheon = AssignedBrand(id: 'gc', code: 'GC', name: 'Gamcheon');
const _inasal = AssignedBrand(id: 'ai', code: 'AI', name: "Aurelia's Inasal");
const _matcha = MenuItem(
  id: 'matcha',
  name: 'Matcha Latte',
  description: '',
  pricesCentavos: {MenuChannel.dineIn: 15000},
);

ProviderContainer _container() => ProviderContainer(
  overrides: [
    assignedBrandsProvider.overrideWithValue([_cafe, _gamcheon, _inasal]),
  ],
);

void main() {
  test('provider survives switching, quantity changes and customization', () {
    final container = _container();
    addTearDown(container.dispose);
    final cart = container.read(cartProvider.notifier);
    container.read(activeBrandProvider.notifier).select(_cafe);
    cart.add(_matcha);
    final id = container.read(cartProvider).single.id;

    for (final brand in [_gamcheon, _inasal]) {
      container.read(activeBrandProvider.notifier).select(brand);
      cart.incrementLine(id);
      cart.decrementLine(id);
      cart.updateLine(
        id,
        {},
        2,
        item: _matcha.withModifierGroups([]),
        kitchenNote: 'Less ice',
      );
      final line = container.read(cartProvider).single;
      expect(line.brandId, _cafe.id);
      expect(line.brandName, _cafe.name);
      expect(line.kitchenNote, 'Less ice');
    }

    // Even matching item IDs must not merge lines from different providers.
    cart.add(_matcha);
    expect(container.read(cartProvider), hasLength(2));
    expect(container.read(cartProvider).last.brandId, _inasal.id);
    cart.updateLine(id, {}, 1, kitchenNote: '');
    expect(container.read(cartProvider), hasLength(2));
    container.read(activeBrandProvider.notifier).select(_cafe);
    cart.add(_matcha);
    expect(container.read(cartProvider).first.quantity, 2);
    expect(container.read(cartProvider), hasLength(2));
  });

  final views = <String, Widget Function()>{
    'cart step': () => CartStepView(onContinue: () {}),
    'cart panel': () => const CartPanel(),
    'review': () => ReviewOrderStepView(onConfirm: () {}),
  };
  for (final entry in views.entries) {
    testWidgets('${entry.key} keeps original provider after switching menus', (
      tester,
    ) async {
      final container = _container();
      addTearDown(container.dispose);
      container.read(activeBrandProvider.notifier).select(_cafe);
      container.read(cartProvider.notifier).add(_matcha);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: Scaffold(body: entry.value())),
        ),
      );
      await tester.pumpAndSettle();

      for (final brand in [_gamcheon, _inasal]) {
        container.read(activeBrandProvider.notifier).select(brand);
        await tester.pumpAndSettle();
        expect(find.text(_cafe.name), findsOneWidget);
        expect(find.text(brand.name), findsNothing);
        expect(find.text('Matcha Latte'), findsOneWidget);
      }
    });
  }
}
