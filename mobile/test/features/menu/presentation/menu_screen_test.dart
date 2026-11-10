import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/features/new_order/data/seed/sample_menu.dart';
import 'package:mobile/features/new_order/presentation/pages/menu_screen.dart';
import 'package:mobile/features/new_order/presentation/widgets/cart_panel/cart_panel.dart';
import 'package:mobile/features/new_order/presentation/widgets/catalog/catalog_search_bar.dart';
import 'package:mobile/features/new_order/presentation/widgets/menu_selector/current_menu_card.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';
import 'package:mobile/shared/widgets/app_header.dart';
import 'package:mobile/shared/widgets/logout_button.dart';

const _phone = Size(412, 1400);
const _narrowPhone = Size(320, 900);
const _desktop = Size(1280, 1000);

Future<ProviderContainer> _pumpMenu(
  WidgetTester tester,
  Size size, {
  void Function(ProviderContainer container)? onInit,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [menuItemsProvider.overrideWith((ref) async => sampleMenu)],
  );
  addTearDown(container.dispose);
  onInit?.call(container);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: counterTheme, home: const MenuScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('MenuScreen layout', () {
    testWidgets(
      'the header displays application title and cashier controls on desktop',
      (tester) async {
        await _pumpMenu(tester, _desktop);

        expect(find.byType(AppHeader), findsOneWidget);
        expect(find.text('Orders'), findsOneWidget);
        expect(find.byType(LogoutButton), findsOneWidget);
        expect(find.byType(CurrentMenuCard), findsOneWidget);
      },
    );

    testWidgets('the header spans the full width', (tester) async {
      await _pumpMenu(tester, _desktop);

      expect(tester.getSize(find.byType(AppHeader)).width, _desktop.width);
    });

    testWidgets('the cart panel docks on a wide screen', (tester) async {
      await _pumpMenu(tester, _desktop);

      expect(find.byType(CartPanel), findsOneWidget);

      final headerBottom = tester.getBottomLeft(find.byType(AppHeader)).dy;
      final panelTop = tester.getTopLeft(find.byType(CartPanel)).dy;

      expect(panelTop, greaterThanOrEqualTo(headerBottom));
    });

    testWidgets(
      'a phone docks the catalog without side cart panel and shows floating cart bar when not empty',
      (tester) async {
        final container = await _pumpMenu(tester, _phone);

        expect(find.byType(AppHeader), findsOneWidget);
        expect(find.byType(CurrentMenuCard), findsOneWidget);

        // On phone, side CartPanel is not docked
        expect(find.byType(CartPanel), findsNothing);

        // AnimatedSlide offset is offscreen when count is 0
        final slideFinder = find.byType(AnimatedSlide);
        expect(
          tester.widget<AnimatedSlide>(slideFinder).offset,
          const Offset(0, 1.2),
        );

        // Add item to cart: offset moves to zero and item count appears
        container.read(cartProvider.notifier).add(sampleMenu[0]);
        await tester.pumpAndSettle();

        expect(tester.widget<AnimatedSlide>(slideFinder).offset, Offset.zero);
        expect(find.text('1 item'), findsOneWidget);
        expect(find.textContaining('View order'), findsOneWidget);
      },
    );

    testWidgets('the current menu card shows the active brand and channel', (
      tester,
    ) async {
      await _pumpMenu(tester, _desktop);

      expect(find.byType(CurrentMenuCard), findsOneWidget);
      expect(find.textContaining('Gamcheon'), findsWidgets);
      expect(find.textContaining('Dine-in'), findsWidgets);
    });

    testWidgets('tapping current menu card opens choose menu modal', (
      tester,
    ) async {
      await _pumpMenu(tester, _phone);

      await tester.tap(find.byType(CurrentMenuCard));
      await tester.pumpAndSettle();

      expect(find.text('Choose menu'), findsOneWidget);
      expect(find.text('Only menus you can manage are shown.'), findsOneWidget);
    });

    testWidgets(
      'the catalog search bar displays search field and unavailable toggle',
      (tester) async {
        await _pumpMenu(tester, _phone);

        expect(find.byType(CatalogSearchBar), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      },
    );

    testWidgets('the header does not overflow on a narrow phone', (
      tester,
    ) async {
      await _pumpMenu(tester, _narrowPhone);

      expect(tester.takeException(), isNull);

      final logout = find.byType(LogoutButton);
      expect(logout, findsOneWidget);
      expect(find.text('Cashier Staff'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(
        tester.getTopRight(logout).dx,
        lessThanOrEqualTo(_narrowPhone.width),
      );
    });
  });
}
