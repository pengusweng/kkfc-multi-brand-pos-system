import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/routes.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/core/models/user_role.dart';
import 'package:mobile/features/auth/providers/session_provider.dart';
import 'package:mobile/features/availability/presentation/widgets/availability_item_card.dart';
import 'package:mobile/features/availability/presentation/widgets/availability_list_skeleton.dart';
import 'package:mobile/features/new_order/presentation/widgets/catalog/catalog_search_bar.dart';
import 'package:mobile/features/new_order/presentation/widgets/menu_selector/choose_menu_modal.dart';
import 'package:mobile/features/new_order/presentation/widgets/menu_selector/current_menu_card.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';
import 'package:mobile/shared/widgets/app_header.dart';
import 'package:mobile/shared/widgets/kkfc_scaffold.dart';
import 'package:mobile/shared/widgets/wave_accents.dart';

/// Availability screen opened from Kitchen Board.
///
/// Features:
/// - App header reflecting Kitchen Board's app bar with title "Availability".
/// - Brand & channel selector mirroring menu_screen.dart brand picker.
/// - Search bar mirroring menu_screen.dart's CatalogSearchBar.
/// - Category filter pills omitted.
/// - Item cards displaying name, category · brand, and availability status.
/// - Interactive 'Change' button opening confirmation dialog to toggle availability.
/// - 'Kitchen Board' button navigating back to the kitchen board.
class KitchenAvailabilityScreen extends ConsumerStatefulWidget {
  const KitchenAvailabilityScreen({
    super.key,
    this.showLogout = true,
    this.onUpdateAvailability,
  });

  final bool showLogout;
  final Future<void> Function(bool availability)? onUpdateAvailability;

  static String _roleLabelFor(UserRole? role) => switch (role) {
    UserRole.kitchenStaff => 'Kitchen Staff',
    UserRole.kitchenHead => 'Kitchen Head',
    UserRole.supervisor => 'Supervisor',
    UserRole.manager => 'Manager',
    UserRole.superadmin => 'Superadmin',
    _ => 'Kitchen Head',
  };

  @override
  ConsumerState<KitchenAvailabilityScreen> createState() =>
      _KitchenAvailabilityScreenState();
}

class _KitchenAvailabilityScreenState
    extends ConsumerState<KitchenAvailabilityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(menuSearchProvider.notifier).clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeBrand = ref.watch(activeBrandProvider);
    final assignedBrands = ref.watch(assignedBrandsProvider);
    final selectedChannel = ref.watch(menuChannelProvider);
    final visibleItemsAsync = ref.watch(visibleMenuItemsProvider);
    final userRole = ref.watch(userRoleProvider);
    final roleLabel = KitchenAvailabilityScreen._roleLabelFor(userRole);

    return KkfcScaffold(
      body: ColoredBox(
        color: KkfcColors.canvas,
        child: Column(
          children: [
            // Top App Bar reflecting kitchen board's app bar with title 'Availability'
            AppHeader(
              title: 'Availability',
              role: roleLabel,
              showLogout: widget.showLogout,
            ),

            // Scrollable Content with background canvas wave accents
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Fluid organic wave landscape & precision contours from the KKFC design system
                  const Positioned.fill(child: KkfcCanvasWaves()),

                  Positioned.fill(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        KkfcSpace.s16,
                        KkfcSpace.s16,
                        KkfcSpace.s16,
                        KkfcSpace.s24,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 820.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Current Menu Selector mirroring menu_screen.dart
                              CurrentMenuCard(
                                brand: activeBrand,
                                channel: selectedChannel,
                                onTap: () async {
                                  final result = await showChooseMenuModal(
                                    context,
                                    brands: assignedBrands,
                                    currentBrand: activeBrand,
                                    currentChannel: selectedChannel,
                                  );
                                  if (result != null) {
                                    if (!context.mounted) return;
                                    ref
                                        .read(activeBrandProvider.notifier)
                                        .select(result.brand);
                                    ref
                                        .read(menuChannelProvider.notifier)
                                        .select(result.channel);
                                  }
                                },
                              ),
                              const SizedBox(height: KkfcSpace.s12),

                              // 2. Search Bar mirroring menu_screen.dart's search bar
                              const CatalogSearchBar(),
                              const SizedBox(height: KkfcSpace.s16),

                              // 3. Menu Item Cards List
                              visibleItemsAsync.when(
                                loading: () => const AvailabilityListSkeleton(),
                                error: (error, _) => Container(
                                  padding: const EdgeInsets.all(KkfcSpace.s20),
                                  decoration: BoxDecoration(
                                    color: KkfcColors.surface,
                                    borderRadius: BorderRadius.circular(
                                      KkfcRadius.md,
                                    ),
                                    border: Border.all(
                                      color: KkfcColors.border,
                                      width: KkfcBorderWidth.thin,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.wifi_off_rounded,
                                        size: 36.0,
                                        color: KkfcColors.borderStrong,
                                      ),
                                      const SizedBox(height: KkfcSpace.s8),
                                      const Text(
                                        "Couldn't load menu items",
                                        style: TextStyle(
                                          fontFamily: KkfcFonts.ibmPlexSans,
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.w600,
                                          color: KkfcColors.ink,
                                        ),
                                      ),
                                      const SizedBox(height: KkfcSpace.s8),
                                      TextButton(
                                        onPressed: () =>
                                            ref.invalidate(menuItemsProvider),
                                        child: const Text('Try again'),
                                      ),
                                    ],
                                  ),
                                ),
                                data: (items) {
                                  if (items.isEmpty) {
                                    final isSearching = ref
                                        .watch(menuSearchProvider)
                                        .trim()
                                        .isNotEmpty;
                                    final isHidingUnavailable = ref.watch(
                                      hideUnavailableProvider,
                                    );
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: KkfcSpace.s48,
                                        horizontal: KkfcSpace.s16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: KkfcColors.surface,
                                        borderRadius: BorderRadius.circular(
                                          KkfcRadius.md,
                                        ),
                                        border: Border.all(
                                          color: KkfcColors.border,
                                          width: KkfcBorderWidth.thin,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          const Icon(
                                            Icons.search_off_rounded,
                                            size: 36.0,
                                            color: KkfcColors.borderStrong,
                                          ),
                                          const SizedBox(height: KkfcSpace.s8),
                                          Text(
                                            isSearching || isHidingUnavailable
                                                ? 'No items matching search'
                                                : 'No menu items available for this brand',
                                            style: const TextStyle(
                                              fontFamily: KkfcFonts.ibmPlexSans,
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w500,
                                              color: KkfcColors.ink3,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return Column(
                                    children: [
                                      for (final item in items)
                                        AvailabilityItemCard(
                                          item: item,
                                          brandName: activeBrand.name,
                                          channel: selectedChannel,
                                          onUpdateAvailability:
                                              widget.onUpdateAvailability,
                                        ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: KkfcSpace.s24),

                              // 4. Kitchen Board Navigation Button
                              Align(
                                alignment: Alignment.centerLeft,
                                child: OutlinedButton(
                                  key: const ValueKey(
                                    'availability-back-to-kitchen-board-button',
                                  ),
                                  onPressed: () {
                                    final navigator = Navigator.maybeOf(
                                      context,
                                    );
                                    if (navigator != null &&
                                        navigator.canPop()) {
                                      navigator.pop();
                                      return;
                                    }
                                    final goRouter = GoRouter.maybeOf(context);
                                    if (goRouter != null) {
                                      if (goRouter.canPop()) {
                                        goRouter.pop();
                                      } else {
                                        goRouter.go(AppRoutes.kitchenTickets);
                                      }
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: KkfcColors.surface,
                                    side: const BorderSide(
                                      color: KkfcColors.ink3,
                                      width: KkfcBorderWidth.thin,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0,
                                      vertical: 12.0,
                                    ),
                                  ),
                                  child: const Text(
                                    'Kitchen Board',
                                    style: TextStyle(
                                      fontFamily: KkfcFonts.ibmPlexSans,
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w700,
                                      color: KkfcColors.ink,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
