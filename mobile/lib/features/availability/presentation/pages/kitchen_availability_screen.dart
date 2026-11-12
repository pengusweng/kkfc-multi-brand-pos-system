import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/routes.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/core/models/user_role.dart';
import 'package:mobile/features/auth/providers/session_provider.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/presentation/widgets/menu_selector/choose_menu_modal.dart';
import 'package:mobile/features/new_order/presentation/widgets/menu_selector/current_menu_card.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';
import 'package:mobile/shared/widgets/app_header.dart';
import 'package:mobile/shared/widgets/kkfc_scaffold.dart';

/// Availability screen opened from Kitchen Board.
///
/// Features:
/// - Brand & channel selector mirroring menu_screen.dart brand picker.
/// - Search bar with real-time item filtering.
/// - Filters omitted by design.
/// - Item cards displaying name, category · brand, and availability status.
/// - Static 'Change' button on each item card.
/// - 'Kitchen Board' button navigating back to the kitchen board.
class KitchenAvailabilityScreen extends ConsumerStatefulWidget {
  const KitchenAvailabilityScreen({super.key});

  @override
  ConsumerState<KitchenAvailabilityScreen> createState() =>
      _KitchenAvailabilityScreenState();
}

class _KitchenAvailabilityScreenState
    extends ConsumerState<KitchenAvailabilityScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static String _labelForAvailability(MenuAvailability availability) =>
      switch (availability) {
        MenuAvailability.available => 'Available',
        MenuAvailability.stockout => 'Out of stock',
        MenuAvailability.manualOff => 'Unavailable',
        MenuAvailability.inactive => 'Inactive',
      };

  @override
  Widget build(BuildContext context) {
    final activeBrand = ref.watch(activeBrandProvider);
    final assignedBrands = ref.watch(assignedBrandsProvider);
    final selectedChannel = ref.watch(menuChannelProvider);
    final menuItemsAsync = ref.watch(menuItemsProvider);
    final userRole = ref.watch(userRoleProvider);

    final roleLabel = switch (userRole) {
      UserRole.kitchenStaff => 'Kitchen Staff',
      UserRole.kitchenHead => 'Kitchen Head',
      UserRole.supervisor => 'Supervisor',
      UserRole.manager => 'Manager',
      UserRole.superadmin => 'Superadmin',
      _ => 'Kitchen Staff',
    };

    return KkfcScaffold(
      body: ColoredBox(
        color: const Color(0xFFF7F5EE),
        child: Column(
          children: [
            // Top App Bar
            AppHeader(
              title: 'Availability',
              compact: true,
              showLogout: false,
              trailing: Container(
                key: const ValueKey('availability-role-pill'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 7.0,
                ),
                decoration: BoxDecoration(
                  color: KkfcColors.shellRoleBg,
                  borderRadius: BorderRadius.circular(KkfcRadius.pill),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      roleLabel,
                      style: const TextStyle(
                        fontFamily: KkfcFonts.ibmPlexSans,
                        fontSize: KkfcTextSizes.textMd,
                        fontWeight: KkfcFontWeights.medium,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4.0),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 18.0,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
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
                        const SizedBox(height: 12.0),

                        // 2. Search Field
                        Container(
                          height: 48.0,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(
                              color: const Color(0xFFDDD6C9),
                              width: 1.0,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search_rounded,
                                size: 22.0,
                                color: Color(0xFF586579),
                              ),
                              const SizedBox(width: 10.0),
                              Expanded(
                                child: TextField(
                                  key: const ValueKey(
                                    'availability-search-field',
                                  ),
                                  controller: _searchController,
                                  onChanged: (val) => setState(
                                    () => _searchQuery = val.trim().toLowerCase(),
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Samgyupsal',
                                    hintStyle: TextStyle(
                                      fontFamily: KkfcFonts.ibmPlexSans,
                                      fontSize: 15.0,
                                      color: Color(0xFF76849A),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: const TextStyle(
                                    fontFamily: KkfcFonts.ibmPlexSans,
                                    fontSize: 15.0,
                                    color: Color(0xFF19293E),
                                  ),
                                ),
                              ),
                              if (_searchQuery.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 20.0,
                                    color: Color(0xFF76849A),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16.0),

                        // 3. Menu Item Cards List
                        menuItemsAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.0),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF19293E),
                              ),
                            ),
                          ),
                          error: (error, _) => Container(
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10.0),
                              border: Border.all(
                                color: const Color(0xFFDDD6C9),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.wifi_off_rounded,
                                  size: 36.0,
                                  color: Color(0xFF76849A),
                                ),
                                const SizedBox(height: 8.0),
                                const Text(
                                  "Couldn't load menu items",
                                  style: TextStyle(
                                    fontFamily: KkfcFonts.ibmPlexSans,
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF19293E),
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                TextButton(
                                  onPressed: () =>
                                      ref.invalidate(menuItemsProvider),
                                  child: const Text('Try again'),
                                ),
                              ],
                            ),
                          ),
                          data: (items) {
                            final filtered = _searchQuery.isEmpty
                                ? items
                                : items.where((item) {
                                    final nameMatch = item.name
                                        .toLowerCase()
                                        .contains(_searchQuery);
                                    final catMatch = (item.category ?? '')
                                        .toLowerCase()
                                        .contains(_searchQuery);
                                    final descMatch = item.description
                                        .toLowerCase()
                                        .contains(_searchQuery);
                                    return nameMatch || catMatch || descMatch;
                                  }).toList();

                            if (filtered.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 48.0,
                                  horizontal: 16.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10.0),
                                  border: Border.all(
                                    color: const Color(0xFFDDD6C9),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.search_off_rounded,
                                      size: 36.0,
                                      color: Color(0xFF76849A),
                                    ),
                                    const SizedBox(height: 10.0),
                                    Text(
                                      _searchQuery.isEmpty
                                          ? 'No menu items available for this brand'
                                          : 'No items matching "$_searchQuery"',
                                      style: const TextStyle(
                                        fontFamily: KkfcFonts.ibmPlexSans,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF586579),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Column(
                              children: [
                                for (final item in filtered)
                                  _buildItemCard(
                                    item: item,
                                    brandName: activeBrand.name,
                                    channel: selectedChannel,
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24.0),

                        // 4. Kitchen Board Navigation Button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton(
                            key: const ValueKey(
                              'availability-back-to-kitchen-board-button',
                            ),
                            onPressed: () {
                              final navigator = Navigator.maybeOf(context);
                              if (navigator != null && navigator.canPop()) {
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
                              backgroundColor: Colors.white,
                              side: const BorderSide(
                                color: Color(0xFF586579),
                                width: 1.0,
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
                                color: Color(0xFF19293E),
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
    );
  }

  Widget _buildItemCard({
    required MenuItem item,
    required String brandName,
    required MenuChannel channel,
  }) {
    final availability = item.availabilityFor(channel);
    final statusLabel = _labelForAvailability(availability);
    final isAvailable = availability == MenuAvailability.available;
    final categoryText = (item.category != null && item.category!.isNotEmpty)
        ? item.category!
        : 'Rice bowl';

    return Container(
      key: ValueKey('availability-item-card-${item.id}'),
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: const Color(0xFFDDD6C9),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontFamily: KkfcFonts.ibmPlexSans,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF19293E),
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  '$categoryText · $brandName',
                  style: const TextStyle(
                    fontFamily: KkfcFonts.ibmPlexSans,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF586579),
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontFamily: KkfcFonts.ibmPlexSans,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isAvailable
                        ? const Color(0xFF19293E)
                        : const Color(0xFF8C3A27),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12.0),
          OutlinedButton(
            key: ValueKey('availability-change-button-${item.id}'),
            onPressed: () {}, // Static first as requested
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(
                color: Color(0xFF586579),
                width: 1.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 22.0,
                vertical: 10.0,
              ),
            ),
            child: const Text(
              'Change',
              style: TextStyle(
                fontFamily: KkfcFonts.ibmPlexSans,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF19293E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
