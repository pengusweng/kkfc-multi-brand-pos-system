import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/routes.dart';
import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/core/models/brand_models.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/presentation/pages/menu_screen.dart';
import 'package:mobile/features/new_order/presentation/widgets/cart_bar.dart';
import 'package:mobile/features/new_order/presentation/widgets/cart_panel/cart_panel.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

const _phoneSize = Size(412, 915);

const _testBrand = AssignedBrand(
  id: 'gamcheon-uuid',
  code: 'GC',
  name: 'Gamcheon',
);

const _testItem = MenuItem(
  id: 'item-1',
  name: 'Gamcheon Samgyupsal',
  description: 'Tasty grilled pork belly bowl',
  pricesCentavos: {MenuChannel.dineIn: 25000},
  availability: {MenuChannel.dineIn: MenuAvailability.available},
);

class _FakeActiveBrandNotifier extends ActiveBrandNotifier {
  _FakeActiveBrandNotifier(this._initial);
  final AssignedBrand _initial;
  @override
  AssignedBrand build() => _initial;
}

void main() {
  testWidgets(
    'Tapping View order on CartBar slides up CartPanel sheet, allowing review and close',
    (tester) async {
      tester.view.physicalSize = _phoneSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final router = GoRouter(
        initialLocation: AppRoutes.menu,
        routes: [
          GoRoute(
            path: AppRoutes.menu,
            builder: (_, _) => const MenuScreen(),
          ),
          GoRoute(
            path: AppRoutes.mobileOrderFlow,
            builder: (_, state) => Scaffold(
              body: Text('Order flow step ${(state.extra as Map?)?['initialStep'] ?? 2}'),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeBrandProvider.overrideWith(
              () => _FakeActiveBrandNotifier(_testBrand),
            ),
            menuItemsProvider.overrideWith((ref) async => [_testItem]),
          ],
          child: MaterialApp.router(
            theme: counterTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially no CartBar because cart is empty
      expect(find.byType(CartPanel), findsNothing);

      // Tap Add to open customization dialog, then Add to order
      final addBtn = find.text('Add');
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      final addToOrderBtn = find.textContaining('Add to order');
      expect(addToOrderBtn, findsOneWidget);
      await tester.tap(addToOrderBtn);
      await tester.pumpAndSettle();

      // Floating CartBar is now visible
      expect(find.byType(CartBar), findsOneWidget);
      expect(find.text('View order · '), findsOneWidget);

      // Tap "View order" on the CartBar
      await tester.tap(find.text('View order · '));
      await tester.pumpAndSettle();

      // CartPanel has slid up as a bottom sheet!
      expect(find.byType(CartPanel), findsOneWidget);
      expect(find.text('Current order'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CartPanel),
          matching: find.text('Gamcheon Samgyupsal'),
        ),
        findsOneWidget,
      );
      expect(find.text('Continue to order details'), findsOneWidget);

      // Tap close button on the sheet header
      final closeBtn = find.byTooltip('Close cart');
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      // CartPanel sheet is dismissed
      expect(find.byType(CartPanel), findsNothing);
      expect(find.byType(CartBar), findsOneWidget);

      // Re-open and tap "Continue to order details"
      await tester.tap(find.text('View order · '));
      await tester.pumpAndSettle();
      expect(find.byType(CartPanel), findsOneWidget);

      await tester.tap(find.text('Continue to order details'));
      await tester.pumpAndSettle();

      // Sheet is dismissed and navigated to mobile order flow at step 3
      expect(find.byType(CartPanel), findsNothing);
      expect(find.text('Order flow step 3'), findsOneWidget);
    },
  );
}
