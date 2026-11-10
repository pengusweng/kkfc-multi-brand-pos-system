import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/routes.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/core/models/brand_models.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/presentation/widgets/catalog/catalog_search_bar.dart';
import 'package:mobile/features/new_order/presentation/widgets/catalog/category_chip.dart';
import 'package:mobile/features/new_order/presentation/widgets/menu_item_card.dart';
import 'package:mobile/features/new_order/presentation/widgets/menu_selector/choose_menu_modal.dart';
import 'package:mobile/features/new_order/presentation/widgets/menu_selector/current_menu_card.dart';
import 'package:mobile/features/new_order/presentation/widgets/menu_states.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

/// The catalog view including menu selector, search/filters, category chips,
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

    final cart = ref.read(cartProvider);

    // Update active channel in notifier
    ref.read(menuChannelProvider.notifier).select(newChannel);

    // If cart has items and any price differs between channels, navigate to repricing screen
    if (cart.isNotEmpty) {
      var hasPriceChange = false;
      for (final line in cart) {
        if (line.totalCentavos(current) != line.totalCentavos(newChannel)) {
          hasPriceChange = true;
          break;
        }
      }

      if (hasPriceChange) {
        context.go(AppRoutes.channelChange);
      }
    }
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

  List<String> _resolveCategories(List<MenuItem>? items) {
    final categories = <String>{'All'};
    if (items != null) {
      for (final item in items) {
        if (item.category != null && item.category!.trim().isNotEmpty) {
          categories.add(item.category!.trim());
        }
      }
    }
    if (categories.length == 1) {
      // Fallback categories if catalog items do not have categories explicitly populated
      return const ['All', 'Rice bowls', 'Sets', 'Snacks'];
    }
    return categories.toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBrand = ref.watch(activeBrandProvider);
    final assignedBrands = ref.watch(assignedBrandsProvider);
    final selectedChannel = ref.watch(menuChannelProvider);
    final selectedCategory = ref.watch(menuCategoryProvider);
    final visibleItems = ref.watch(visibleMenuItemsProvider);
    final allItems = ref.watch(menuItemsProvider).asData?.value;
    final categories = _resolveCategories(allItems);

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
                const SizedBox(height: KkfcSpace.s12),

                // 3. Category chips filter (dynamically derived with 40dp touch target clearance)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final cat in categories) ...[
                        CategoryChip(
                          label: cat,
                          selected: selectedCategory == cat,
                          onTap: () =>
                              ref.read(menuCategoryProvider.notifier).set(cat),
                        ),
                        const SizedBox(width: KkfcSpace.s8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 4. Menu Items Grid / List with native viewport virtualization (Zero shrinkWrap)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            isWide ? KkfcSpace.s20 : KkfcSpace.s16,
            KkfcSpace.s4,
            isWide ? KkfcSpace.s20 : KkfcSpace.s16,
            bottomPadding,
          ),
          sliver: visibleItems.when(
            loading: () => SliverToBoxAdapter(
              child: MenuGridSkeleton(isWide: isWide),
            ),
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
                final isSearching =
                    ref.watch(menuSearchProvider).trim().isNotEmpty;
                final isCategoryFiltered =
                    ref.watch(menuCategoryProvider) != 'All';
                final isHidingUnavailable =
                    ref.watch(hideUnavailableProvider);

                if (isSearching || isCategoryFiltered || isHidingUnavailable) {
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
