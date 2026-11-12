import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models/user_role.dart';
import '../features/auth/providers/session_provider.dart';
import '../features/auth/presentation/pages/login_screen.dart';
import '../features/new_order/presentation/pages/menu_screen.dart';
import '../features/new_order/presentation/pages/mobile_order_flow_screen.dart';
import '../features/orders/screens/orders_screen.dart';
import '../features/availability/presentation/pages/kitchen_availability_screen.dart';
import '../features/order_entry/data/models/order_confirmed_view_data.dart';
import '../features/order_entry/data/models/order_not_sent_view_data.dart';
import '../features/order_entry/data/models/duplicate_platform_order_view_data.dart';
import '../features/order_entry/data/models/order_entry_view_data.dart';
import '../features/order_entry/presentation/pages/order_confirmed_screen.dart';
import '../features/order_entry/presentation/pages/order_not_sent_screen.dart';
import '../features/order_entry/presentation/pages/duplicate_platform_order_screen.dart';
import '../features/order_entry/presentation/pages/order_entry_screen.dart';
import '../features/order_entry/presentation/pages/platform_reference_screen.dart';

import '../features/orders/cancel/presentation/pages/cancel_order_screen.dart';
import '../features/kitchen/kitchen_board/presentation/pages/kitchen_board_screen.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen<bool>(sessionProvider, (_, _) => refresh.value++);
  ref.listen<UserRole?>(userRoleProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: refresh,
    redirect: (context, state) {
      final isLoggedIn = ref.read(sessionProvider);
      final role = ref.read(userRoleProvider);
      final onLogin = state.matchedLocation == AppRoutes.login;

      if (!isLoggedIn && !onLogin) {
        return AppRoutes.login;
      }

      final canAccessPos = role?.canAccessPos ?? true;
      final canAccessKitchen = role?.canAccessKitchenBoard ?? false;
      final onKitchenPage = state.matchedLocation == AppRoutes.kitchenTickets ||
          state.matchedLocation == AppRoutes.availability;

      if (isLoggedIn && onLogin) {
        return canAccessPos ? AppRoutes.menu : AppRoutes.kitchenTickets;
      }

      if (isLoggedIn) {
        // Kitchen staff / kitchen head can only see the kitchen tickets and availability pages.
        // Supervisors and superadmins may switch between POS and KDS.
        if (!canAccessPos && !onKitchenPage) {
          return AppRoutes.kitchenTickets;
        }

        // Roles without kitchen access must never see the kitchen tickets page.
        if (!canAccessKitchen && state.matchedLocation == AppRoutes.kitchenTickets) {
          return AppRoutes.menu;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: LoginScreen(),
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 240),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.kitchenTickets,
        builder: (context, state) => const KitchenBoardScreen(),
      ),
      GoRoute(
        path: AppRoutes.menu,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const MenuScreen(),
          transitionDuration: const Duration(milliseconds: 450),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.025),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.mobileOrderFlow,
        builder: (context, state) {
          final extra = state.extra;
          final initialStep =
              extra is Map<String, dynamic> && extra['initialStep'] is int
              ? extra['initialStep'] as int
              : 2;
          return MobileOrderFlowScreen(initialStep: initialStep);
        },
      ),
      GoRoute(
        path: AppRoutes.orders,
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: AppRoutes.cancelOrder,
        builder: (context, state) {
          // Live mode is opt-in: /orders/cancel?orderId=<uuid>[&orderCode=GC-00001]
          // Without orderId the screen runs the demo states with sample data.
          final query = state.uri.queryParameters;
          return CancelOrderScreen(
            orderId: query['orderId'],
            orderCode: query['orderCode'],
            ticketNumber: query['ticketNumber'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.availability,
        builder: (context, state) => const KitchenAvailabilityScreen(),
      ),
      GoRoute(
        path: AppRoutes.orderEntry,
        builder: (context, state) {
          final data = state.extra;
          return data is OrderEntryViewData
              ? OrderEntryScreen(data: data)
              : const OrderEntryScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.orderConfirmed,
        builder: (context, state) {
          final data = state.extra;
          return OrderConfirmedScreen(
            data: data is OrderConfirmedViewData
                ? data
                : OrderConfirmedViewData.sample,
            onNewOrder: () => context.go(AppRoutes.menu),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.orderNotSent,
        builder: (context, state) {
          final data = state.extra;
          return OrderNotSentScreen(
            data: data is OrderNotSentViewData
                ? data
                : OrderNotSentViewData.sample,
            onEditOrder: () => context.go(AppRoutes.menu),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.duplicatePlatformOrder,
        builder: (context, state) {
          final data = state.extra;
          return DuplicatePlatformOrderScreen(
            data: data is DuplicatePlatformOrderViewData
                ? data
                : DuplicatePlatformOrderViewData.sample,
            onBackToOrder: () => context.go(AppRoutes.menu),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.platformReference,
        builder: (context, state) => const PlatformReferenceScreen(),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
