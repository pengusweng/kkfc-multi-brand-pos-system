import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/router.dart';
import 'package:mobile/app/routes.dart';
import 'package:mobile/core/models/user_role.dart';
import 'package:mobile/features/auth/providers/session_provider.dart';
import 'package:mobile/features/availability/providers/availability_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';
import 'package:mobile/shared/widgets/workspace_switcher.dart';

void main() {
  test('only SUPERADMIN and SUPERVISOR can switch workspaces', () {
    for (final role in UserRole.values) {
      expect(
        role.canSwitchWorkspace,
        role == UserRole.superadmin || role == UserRole.supervisor,
        reason: role.apiValue,
      );
    }
    expect(UserRole.kitchenStaff.canAccessPos, isFalse);
    expect(UserRole.kitchenHead.canAccessPos, isFalse);
    expect(UserRole.supervisor.canAccessKitchenBoard, isTrue);
    expect(UserRole.superadmin.canAccessKitchenBoard, isTrue);
    expect(UserRole.manager.canAccessKitchenBoard, isFalse);
  });

  Future<GoRouter> pump(WidgetTester tester, UserRole role) async {
    final router = GoRouter(
      initialLocation: AppRoutes.menu,
      routes: [
        GoRoute(
          path: AppRoutes.menu,
          builder: (_, _) => const Scaffold(
            body: Column(children: [WorkspaceSwitcher(), Text('POS page')]),
          ),
        ),
        GoRoute(
          path: AppRoutes.kitchenTickets,
          builder: (_, _) => const Scaffold(
            body: Column(children: [WorkspaceSwitcher(), Text('KDS page')]),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userRoleProvider.overrideWith(() => _FixedRole(role)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('SUPERADMIN can switch from POS to KDS and back', (tester) async {
    await pump(tester, UserRole.superadmin);
    expect(find.byKey(const ValueKey('workspace-switcher')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('workspace-switcher')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('workspace-option-KDS')));
    await tester.pumpAndSettle();
    expect(find.text('KDS page'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('workspace-switcher')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('workspace-option-POS')));
    await tester.pumpAndSettle();
    expect(find.text('POS page'), findsOneWidget);
  });

  testWidgets('switcher is hidden for roles that cannot switch', (
    tester,
  ) async {
    await pump(tester, UserRole.kitchenHead);
    expect(find.byKey(const ValueKey('workspace-switcher')), findsNothing);
  });

  testWidgets('SUPERVISOR defaults to menu screen on login', (tester) async {
    final container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith((ref) => true),
        userRoleProvider.overrideWith(() => _FixedRole(UserRole.supervisor)),
        menuItemsProvider.overrideWith((ref) async => []),
        availabilityMenuItemsProvider.overrideWith((ref) async => []),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    router.go(AppRoutes.login);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.menu);
  });

  testWidgets('KITCHEN_HEAD defaults to kitchenTickets on login', (tester) async {
    final container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith((ref) => true),
        userRoleProvider.overrideWith(() => _FixedRole(UserRole.kitchenHead)),
        menuItemsProvider.overrideWith((ref) async => []),
        availabilityMenuItemsProvider.overrideWith((ref) async => []),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    router.go(AppRoutes.login);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.kitchenTickets,
    );
  });
}

class _FixedRole extends UserRoleNotifier {
  _FixedRole(this._role);
  final UserRole _role;

  @override
  UserRole? build() => _role;
}
