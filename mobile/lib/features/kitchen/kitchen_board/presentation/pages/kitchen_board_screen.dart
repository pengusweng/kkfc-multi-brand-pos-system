import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/core/models/user_role.dart';
import 'package:mobile/features/auth/providers/session_provider.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_ticket.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/kitchen_board_lanes_view.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/kitchen_board_toolbar.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/ticket_status_dialog/kitchen_ticket_status_dialog.dart';
import 'package:mobile/features/kitchen/kitchen_board/providers/kitchen_board_providers.dart';
import 'package:mobile/shared/widgets/app_header.dart';
import 'package:mobile/shared/widgets/kkfc_scaffold.dart';
import 'package:mobile/shared/widgets/wave_accents.dart';

/// Main Kitchen Display System (KDS) four-lane board screen.
class KitchenBoardScreen extends ConsumerWidget {
  const KitchenBoardScreen({
    super.key,
    this.showLogout = true,
    this.onTicketDetails,
  });

  final bool showLogout;
  final ValueChanged<KitchenBoardTicket>? onTicketDetails;

  static String _roleLabelFor(UserRole? role) => switch (role) {
    UserRole.kitchenStaff => 'Kitchen Staff',
    UserRole.kitchenHead => 'Kitchen Head',
    UserRole.supervisor => 'Supervisor',
    UserRole.manager => 'Manager',
    UserRole.superadmin => 'Superadmin',
    _ => 'Kitchen Head',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<String?>(sessionTokenProvider, (previous, next) {
      if (next != null && next != previous) {
        ref.read(kitchenBoardProvider.notifier).refresh(force: true);
      }
    });

    ref.watch(userRoleInitializerProvider);
    final boardState = ref.watch(kitchenBoardProvider);
    final userRole = ref.watch(userRoleProvider);
    final roleLabel = _roleLabelFor(userRole);

    return KkfcScaffold(
      body: ColoredBox(
        color: KkfcColors.canvas,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(
              title: 'Kitchen',
              role: roleLabel,
              showLogout: showLogout,
            ),
            KitchenBoardToolbar(
              activeCount: boardState.activeCount,
              updatedAt: boardState.updatedAt,
              isRefreshing: boardState.isRefreshing || boardState.isLoading,
              isReadOnly: userRole?.isKitchenReadOnlyExceptQc ?? false,
              onRefresh: () =>
                  ref.read(kitchenBoardProvider.notifier).refresh(),
            ),
            if (boardState.errorMessage != null)
              _KitchenBoardErrorBanner(
                message: boardState.errorMessage!,
                onRetry: () =>
                    ref.read(kitchenBoardProvider.notifier).refresh(),
              ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Fluid organic wave landscape & precision contours from the KKFC design system
                  const Positioned.fill(
                    child: KkfcCanvasWaves(),
                  ),

                  // Responsive KDS 4-lane board
                  Positioned.fill(
                    child: KitchenBoardLanesView(
                      state: boardState,
                      userRole: userRole,
                      canPassQc: userRole?.canPassQc ?? false,
                      onTicketAction: (ticket) => showKitchenTicketStatusDialog(
                        context,
                        ticket: ticket,
                      ),
                      onTicketDetails:
                          onTicketDetails ??
                          (ticket) => showKitchenTicketStatusDialog(
                            context,
                            ticket: ticket,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KitchenBoardErrorBanner extends StatelessWidget {
  const _KitchenBoardErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('kitchen-board-error-banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: KkfcSpace.s20,
        vertical: KkfcSpace.s8,
      ),
      decoration: const BoxDecoration(
        color: KkfcColors.dangerBg,
        border: Border(
          bottom: BorderSide(
            color: KkfcColors.dangerBorder,
            width: KkfcBorderWidth.thin,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: KkfcColors.danger,
          ),
          const SizedBox(width: KkfcSpace.s8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: KkfcFonts.ibmPlexSans,
                fontSize: KkfcTextSizes.textSm,
                fontWeight: KkfcFontWeights.medium,
                color: KkfcColors.danger,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: KkfcColors.danger,
              padding: const EdgeInsets.symmetric(
                horizontal: KkfcSpace.s8,
                vertical: KkfcSpace.s4,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                fontFamily: KkfcFonts.ibmPlexSans,
                fontSize: KkfcTextSizes.textSm,
                fontWeight: KkfcFontWeights.bold,
                color: KkfcColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
