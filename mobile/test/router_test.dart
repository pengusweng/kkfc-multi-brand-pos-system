import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/core/models/user_role.dart';
import 'package:mobile/features/auth/presentation/pages/login_screen.dart';
import 'package:mobile/features/auth/providers/session_provider.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/pages/kitchen_board_screen.dart';
import 'package:mobile/features/new_order/presentation/pages/menu_screen.dart';

void main() {
  test(
    'UserRole.isKitchen includes supervisor, kitchenHead, and kitchenStaff',
    () {
      expect(UserRole.supervisor.isKitchen, isTrue);
      expect(UserRole.kitchenHead.isKitchen, isTrue);
      expect(UserRole.kitchenStaff.isKitchen, isTrue);

      expect(UserRole.cashierStaff.isKitchen, isFalse);
      expect(UserRole.manager.isKitchen, isFalse);
      expect(UserRole.superadmin.isKitchen, isFalse);
      expect(UserRole.recipeManager.isKitchen, isFalse);
      expect(UserRole.inventoryStaff.isKitchen, isFalse);
    },
  );

  testWidgets('logged-out users start on the login screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('supervisor login reroutes from login to the menu page', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialTokenProvider.overrideWithValue('mock-supervisor-token'),
          initialRoleProvider.overrideWithValue(UserRole.supervisor),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    // Supervisor defaults to the menu screen, but retains switcher in header
    expect(find.byType(MenuScreen), findsOneWidget);
    expect(find.byType(KitchenBoardScreen), findsNothing);
    expect(find.text('Supervisor'), findsOneWidget);
  });

  testWidgets(
    'kitchen staff login reroutes from login to the kitchen tickets page',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initialTokenProvider.overrideWithValue('mock-kitchen-staff-token'),
            initialRoleProvider.overrideWithValue(UserRole.kitchenStaff),
          ],
          child: const App(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(KitchenBoardScreen), findsOneWidget);
      expect(find.byType(MenuScreen), findsNothing);
    },
  );

  testWidgets('cashier staff login routes to the menu page', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialTokenProvider.overrideWithValue('mock-cashier-token'),
          initialRoleProvider.overrideWithValue(UserRole.cashierStaff),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MenuScreen), findsOneWidget);
    expect(find.byType(KitchenBoardScreen), findsNothing);
  });
}
