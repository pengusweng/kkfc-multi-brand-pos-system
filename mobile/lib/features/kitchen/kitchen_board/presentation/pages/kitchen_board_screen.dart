import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/app/routes.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/core/models/user_role.dart';
import 'package:mobile/features/auth/providers/session_provider.dart';
import 'package:mobile/features/availability/presentation/pages/kitchen_availability_screen.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_ticket.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/kitchen_board_lanes_view.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/kitchen_board_toolbar.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/ticket_status_dialog/kitchen_ticket_status_dialog.dart';
import 'package:mobile/features/kitchen/kitchen_board/providers/kitchen_board_providers.dart';
import 'package:mobile/shared/widgets/app_header.dart';
import 'package:mobile/shared/widgets/kkfc_scaffold.dart';
import 'package:mobile/shared/widgets/wave_accents.dart';

/// Main Kitchen Display System (KDS) four-lane board screen.
class KitchenBoardScreen extends ConsumerStatefulWidget {
  const KitchenBoardScreen({
    super.key,
    this.showLogout = true,
    this.onTicketDetails,
    this.onAvailability,
    this.imagePicker,
    this.onPickImage,
  });

  final bool showLogout;
  final ValueChanged<KitchenBoardTicket>? onTicketDetails;
  final VoidCallback? onAvailability;
  final ImagePicker? imagePicker;
  final Future<XFile?> Function(ImageSource source)? onPickImage;

  static String _roleLabelFor(UserRole? role) => switch (role) {
    UserRole.kitchenStaff => 'Kitchen Staff',
    UserRole.kitchenHead => 'Kitchen Head',
    UserRole.supervisor => 'Supervisor',
    UserRole.manager => 'Manager',
    UserRole.superadmin => 'Superadmin',
    _ => 'Kitchen Head',
  };

  @override
  ConsumerState<KitchenBoardScreen> createState() => _KitchenBoardScreenState();
}

class _KitchenBoardScreenState extends ConsumerState<KitchenBoardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _toolbarFade;
  late final Animation<Offset> _toolbarSlide;
  late final Animation<double> _boardFade;
  late final Animation<Offset> _boardSlide;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _headerFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.06), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
          ),
        );
    _toolbarFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.08, 0.65, curve: Curves.easeOutCubic),
    );
    _toolbarSlide =
        Tween<Offset>(begin: const Offset(0, -0.04), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.08, 0.65, curve: Curves.easeOutCubic),
          ),
        );
    _boardFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.14, 1.0, curve: Curves.easeOutCubic),
    );
    _boardSlide = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.14, 1.0, curve: Curves.easeOutCubic),
          ),
        );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_entranceController.isAnimating && !_entranceController.isCompleted) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _entranceController.value = 1.0;
      } else {
        _entranceController.forward();
      }
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(sessionTokenProvider, (previous, next) {
      if (next != null && next != previous) {
        ref.read(kitchenBoardProvider.notifier).refresh(force: true);
      }
    });

    ref.watch(userRoleInitializerProvider);
    final boardState = ref.watch(kitchenBoardProvider);
    final userRole = ref.watch(userRoleProvider);
    final roleLabel = KitchenBoardScreen._roleLabelFor(userRole);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return KkfcScaffold(
      body: ColoredBox(
        color: KkfcColors.canvas,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SlideTransition(
              position: _headerSlide,
              child: FadeTransition(
                opacity: _headerFade,
                child: AppHeader(
                  title: 'Kitchen',
                  role: roleLabel,
                  showLogout: widget.showLogout,
                ),
              ),
            ),
            SlideTransition(
              position: _toolbarSlide,
              child: FadeTransition(
                opacity: _toolbarFade,
                child: KitchenBoardToolbar(
                  activeCount: boardState.activeCount,
                  updatedAt: boardState.updatedAt,
                  isRefreshing: boardState.isRefreshing || boardState.isLoading,
                  isReadOnly: userRole?.isKitchenReadOnlyExceptQc ?? false,
                  onRefresh: () =>
                      ref.read(kitchenBoardProvider.notifier).refresh(),
                  onAvailability:
                      widget.onAvailability ??
                      () {
                        if (GoRouter.maybeOf(context) != null) {
                          context.push(AppRoutes.availability);
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const KitchenAvailabilityScreen(),
                            ),
                          );
                        }
                      },
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: reduceMotion ? Duration.zero : KkfcMotion.durOverlay,
              reverseDuration: reduceMotion
                  ? Duration.zero
                  : KkfcMotion.durExit,
              switchInCurve: KkfcMotion.easeOut,
              switchOutCurve: KkfcMotion.easeIn,
              transitionBuilder: (child, animation) => SizeTransition(
                sizeFactor: animation,
                alignment: Alignment.topCenter,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: boardState.errorMessage != null
                  ? _KitchenBoardErrorBanner(
                      key: ValueKey('error-banner-${boardState.errorMessage}'),
                      message: boardState.errorMessage!,
                      onRetry: () =>
                          ref.read(kitchenBoardProvider.notifier).refresh(),
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Fluid organic wave landscape & precision contours from the KKFC design system
                  const Positioned.fill(child: KkfcCanvasWaves()),

                  // Responsive KDS 4-lane board
                  Positioned.fill(
                    child: SlideTransition(
                      position: _boardSlide,
                      child: FadeTransition(
                        opacity: _boardFade,
                        child: KitchenBoardLanesView(
                          state: boardState,
                          userRole: userRole,
                          canPassQc: userRole?.canPassQc ?? false,
                          onTicketAction: (ticket) =>
                              showKitchenTicketStatusDialog(
                                context,
                                ticket: ticket,
                                imagePicker: widget.imagePicker,
                                onPickImage: widget.onPickImage,
                              ),
                          onTicketDetails:
                              widget.onTicketDetails ??
                              (ticket) => showKitchenTicketStatusDialog(
                                context,
                                ticket: ticket,
                                imagePicker: widget.imagePicker,
                                onPickImage: widget.onPickImage,
                              ),
                        ),
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
    super.key,
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
