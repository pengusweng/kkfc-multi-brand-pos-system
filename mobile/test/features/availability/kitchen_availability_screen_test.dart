import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/core/models/brand_models.dart';
import 'package:mobile/core/models/user_role.dart';
import 'package:mobile/features/auth/providers/session_provider.dart';
import 'package:mobile/features/availability/presentation/pages/kitchen_availability_screen.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/kitchen_board_toolbar.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/data/seed/sample_menu.dart';
import 'package:mobile/features/new_order/presentation/widgets/menu_selector/choose_menu_modal.dart';
import 'package:mobile/features/new_order/presentation/widgets/menu_selector/current_menu_card.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

class _TestUserRoleNotifier extends UserRoleNotifier {
  _TestUserRoleNotifier(this._role);
  final UserRole _role;

  @override
  UserRole? build() => _role;
}

void main() {
  const testBrands = [
    AssignedBrand(
      id: 'brand-gamcheon',
      code: 'GC',
      name: 'Gamcheon',
      channels: [MenuChannel.dineIn, MenuChannel.takeaway],
    ),
    AssignedBrand(
      id: 'brand-aurelias',
      code: 'AI',
      name: "Aurelia's Inasal",
      channels: [MenuChannel.dineIn],
    ),
    AssignedBrand(
      id: 'brand-kingkungs',
      code: 'KK',
      name: 'King Kungs Kafé',
      channels: [MenuChannel.dineIn, MenuChannel.takeaway],
    ),
  ];

  Widget buildAvailabilityTestWidget({
    UserRole userRole = UserRole.kitchenStaff,
    List<MenuItem>? menuItems,
  }) {
    return ProviderScope(
      overrides: [
        userRoleProvider.overrideWith(() => _TestUserRoleNotifier(userRole)),
        assignedBrandsProvider.overrideWith((ref) => testBrands),
        menuItemsProvider.overrideWith(
          (ref) async => menuItems ?? sampleGamcheonMenu,
        ),
      ],
      child: MaterialApp(
        theme: counterTheme,
        home: const KitchenAvailabilityScreen(),
      ),
    );
  }

  group('KitchenBoardToolbar Availability button', () {
    testWidgets(
      'renders availability button beside refresh button with matching design and triggers callback',
      (tester) async {
        bool availabilityTapped = false;
        bool refreshTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: counterTheme,
            home: Scaffold(
              body: KitchenBoardToolbar(
                activeCount: 5,
                updatedAt: DateTime.now(),
                onRefresh: () => refreshTapped = true,
                onAvailability: () => availabilityTapped = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final availButton = find.byKey(
          const ValueKey('kitchen-board-availability-button'),
        );
        final refreshButton = find.byKey(
          const ValueKey('kitchen-board-refresh-button'),
        );

        expect(availButton, findsOneWidget);
        expect(refreshButton, findsOneWidget);
        expect(find.text('Availability'), findsOneWidget);
        expect(find.text('Refresh'), findsOneWidget);

        await tester.tap(availButton);
        await tester.pumpAndSettle();
        expect(availabilityTapped, isTrue);

        await tester.tap(refreshButton);
        await tester.pumpAndSettle();
        expect(refreshTapped, isTrue);
      },
    );
  });

  group('KitchenAvailabilityScreen UI & behavior', () {
    testWidgets(
      'renders header with role pill, CurrentMenuCard brand picker, search field, and excludes category filter pills',
      (tester) async {
        await tester.pumpWidget(buildAvailabilityTestWidget());
        await tester.pumpAndSettle();

        // 1. Header & Role Pill
        expect(find.text('Availability'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('availability-role-pill')),
          findsOneWidget,
        );
        expect(find.text('Kitchen Staff'), findsOneWidget);

        // 2. Mirrors menu_screen.dart brand picker (CurrentMenuCard)
        expect(find.byType(CurrentMenuCard), findsOneWidget);
        expect(find.text('Current menu'), findsOneWidget);
        expect(find.text('Gamcheon · Dine-in'), findsOneWidget);

        // 3. Search Bar with hint
        expect(
          find.byKey(const ValueKey('availability-search-field')),
          findsOneWidget,
        );
        expect(find.text('Samgyupsal'), findsOneWidget);

        // 4. Filters MUST NOT be included (no category filter chips like "All", "Sets", "Snacks")
        expect(find.widgetWithText(ActionChip, 'All'), findsNothing);
        expect(find.widgetWithText(FilterChip, 'All'), findsNothing);
        expect(find.widgetWithText(ActionChip, 'Rice bowls'), findsNothing);
        expect(find.widgetWithText(ActionChip, 'Sets'), findsNothing);
        expect(find.widgetWithText(ActionChip, 'Snacks'), findsNothing);

        // 5. Item Card: Gamcheon Samgyupsal Rice Bowl
        expect(
          find.byKey(
            const ValueKey('availability-item-card-gamcheon-samgyupsal'),
          ),
          findsOneWidget,
        );
        expect(find.text('Gamcheon Samgyupsal Rice Bowl'), findsOneWidget);
        expect(find.text('Rice bowls · Gamcheon'), findsOneWidget);
        expect(find.text('Available'), findsWidgets);

        // 6. Change button is static
        final changeButton = find.byKey(
          const ValueKey('availability-change-button-gamcheon-samgyupsal'),
        );
        expect(changeButton, findsOneWidget);
        expect(find.text('Change'), findsWidgets);
        await tester.tap(changeButton);
        await tester.pumpAndSettle();
        // Still available (static)
        expect(find.text('Available'), findsWidgets);

        // 7. Kitchen Board button
        expect(
          find.byKey(
            const ValueKey('availability-back-to-kitchen-board-button'),
          ),
          findsOneWidget,
        );
        expect(find.text('Kitchen Board'), findsOneWidget);
      },
    );

    testWidgets('tapping CurrentMenuCard opens ChooseMenuModal', (
      tester,
    ) async {
      await tester.pumpWidget(buildAvailabilityTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CurrentMenuCard));
      await tester.pumpAndSettle();

      expect(find.byType(ChooseMenuModal), findsOneWidget);
      expect(find.text('Choose menu'), findsOneWidget);
      expect(find.text('Switch menu'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Cancel closes modal
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(ChooseMenuModal), findsNothing);
    });

    testWidgets('search field filters menu item cards in real time', (
      tester,
    ) async {
      await tester.pumpWidget(buildAvailabilityTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Gamcheon Samgyupsal Rice Bowl'), findsOneWidget);

      final searchField = find.byKey(
        const ValueKey('availability-search-field'),
      );
      await tester.enterText(searchField, 'samgyupsal');
      await tester.pumpAndSettle();

      expect(find.text('Gamcheon Samgyupsal Rice Bowl'), findsOneWidget);

      // Search non-existent
      await tester.enterText(searchField, 'non-existent-xyz');
      await tester.pumpAndSettle();

      expect(find.text('Gamcheon Samgyupsal Rice Bowl'), findsNothing);
      expect(find.text('No items matching "non-existent-xyz"'), findsOneWidget);
    });

    testWidgets('Kitchen Board button pops navigator back', (tester) async {
      bool popped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: counterTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProviderScope(
                        overrides: [
                          assignedBrandsProvider.overrideWith(
                            (ref) => testBrands,
                          ),
                          menuItemsProvider.overrideWith(
                            (ref) async => sampleGamcheonMenu,
                          ),
                        ],
                        child: const KitchenAvailabilityScreen(),
                      ),
                    ),
                  ).then((_) => popped = true);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(KitchenAvailabilityScreen), findsOneWidget);

      final backButton = find.byKey(
        const ValueKey('availability-back-to-kitchen-board-button'),
      );
      await tester.ensureVisible(backButton);
      await tester.pumpAndSettle();
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(KitchenAvailabilityScreen), findsNothing);
      expect(popped, isTrue);
    });
  });
}
