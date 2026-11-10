import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/core/models/brand_models.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/presentation/widgets/catalog/catalog_search_bar.dart';
import 'package:mobile/features/new_order/presentation/widgets/menu_item_card.dart';
import 'package:mobile/features/new_order/presentation/widgets/menu_selector/choose_menu_modal.dart';
import 'package:mobile/features/new_order/presentation/widgets/menu_selector/current_menu_card.dart';
import 'package:mobile/features/new_order/presentation/widgets/menu_states.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

/// The catalog view including menu selector, search/availability toggle,
/// and virtualized menu item grid/list.
class MenuCatalogView extends ConsumerWidget {
  const MenuCatalogView({
    super.key,
    required this.isWide,
    required this.bottomPadding,
  });

  final bool isWide;
  final double bottomPadding;

  void _onChannelSelected(
    BuildContext context,
    WidgetRef ref,
    MenuChannel newChannel,
  ) {
    final current = ref.read(menuChannelProvider);
    if (current == newChannel) return;

    // Update active channel in notifier directly without navigating to repricing screen
    ref.read(menuChannelProvider.notifier).select(newChannel);
  }

  void _onMenuSwitched(
    BuildContext context,
    WidgetRef ref,
    AssignedBrand newBrand,
    MenuChannel newChannel,
  ) {
    final currentBrand = ref.read(activeBrandProvider);
    final currentChannel = ref.read(menuChannelProvider);

    if (newBrand.id != currentBrand.id) {
      ref.read(activeBrandProvider.notifier).select(newBrand);
    }

    if (newChannel != currentChannel) {
      _onChannelSelected(context, ref, newChannel);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBrand = ref.watch(activeBrandProvider);
    final assignedBrands = ref.watch(assignedBrandsProvider);
    final selectedChannel = ref.watch(menuChannelProvider);
    final visibleItems = ref.watch(visibleMenuItemsProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isWide ? KkfcSpace.s20 : KkfcSpace.s16,
              KkfcSpace.s16,
              isWide ? KkfcSpace.s20 : KkfcSpace.s16,
              KkfcSpace.s12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Current Menu Selector ("Gamcheon · Dine-in >")
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
                      _onMenuSwitched(
                        context,
                        ref,
                        result.brand,
                        result.channel,
                      );
                    }
                  },
                ),
                const SizedBox(height: KkfcSpace.s12),

                // 2. Search field + Unavailable button with tactile press feedback
                const CatalogSearchBar(),
              ],
            ),
          ),
        ),

        // 3. Menu Items Grid / List with native viewport virtualization (Zero shrinkWrap)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            isWide ? KkfcSpace.s20 : KkfcSpace.s16,
            KkfcSpace.s4,
            isWide ? KkfcSpace.s20 : KkfcSpace.s16,
            bottomPadding,
          ),
          sliver: visibleItems.when(
            loading: () =>
                SliverToBoxAdapter(child: MenuGridSkeleton(isWide: isWide)),
            error: (_, _) => SliverToBoxAdapter(
              child: MenuMessageCard(
                icon: Icons.wifi_off,
                title: "Couldn't load the menu",
                body: 'Check the connection, then try again.',
                actionLabel: 'Try again',
                onAction: () => ref.invalidate(menuItemsProvider),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                final isSearching = ref
                    .watch(menuSearchProvider)
                    .trim()
                    .isNotEmpty;
                final isHidingUnavailable = ref.watch(hideUnavailableProvider);

                if (isSearching || isHidingUnavailable) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(KkfcSpace.s40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 40,
                              color: Color(0xFF76849A),
                            ),
                            SizedBox(height: KkfcSpace.s12),
                            Text(
                              'No items in this category or matching search',
                              style: TextStyle(
                                fontFamily: KkfcFonts.ibmPlexSans,
                                color: Color(0xFF586579),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverToBoxAdapter(
                  child: MenuMessageCard(
                    icon: Icons.restaurant_menu_outlined,
                    title: 'No menu items available',
                    body: 'No items found in this brand catalog.',
                    actionLabel: 'Refresh catalog',
                    onAction: () => ref.invalidate(menuItemsProvider),
                  ),
                );
              }

              return isWide
                  ? SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16.0,
                            mainAxisSpacing: 16.0,
                            mainAxisExtent: 160.0,
                          ),
                      itemCount: items.length,
                      itemBuilder: (context, index) => MenuItemCard(
                        item: items[index],
                        channel: selectedChannel,
                        compact: false,
                      ),
                    )
                  : SliverList.separated(
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12.0),
                      itemBuilder: (context, index) => MenuItemCard(
                        item: items[index],
                        channel: selectedChannel,
                        compact: true,
                      ),
                    );
            },
          ),
        ),
      ],
    );
  }
}
