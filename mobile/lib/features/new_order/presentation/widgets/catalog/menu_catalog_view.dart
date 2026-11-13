import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/app_updates/optional_update_notice.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBrand = ref.watch(activeBrandProvider);
    final assignedBrands = ref.watch(assignedBrandsProvider);
    final selectedChannel = ref.watch(menuChannelProvider);
    final visibleItems = ref.watch(visibleMenuItemsProvider);
    final visibleCount = visibleItems.asData?.value.length;

    return RefreshIndicator(
      onRefresh: () async {
        try {
          ref.invalidate(menuItemsProvider);
          await ref.read(menuItemsProvider.future);
        } catch (_) {
          // The catalog's error state provides the retry action.
        }
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                  const OptionalUpdateNotice(),
                  // Provider selection; channels are selected in order details.
                  CurrentMenuCard(
                    brand: activeBrand,
                    channel: selectedChannel,
                    showChannel: false,
                    onTap: () async {
                      final result = await showChooseMenuModal(
                        context,
                        brands: assignedBrands,
                        currentBrand: activeBrand,
                        currentChannel: selectedChannel,
                        showChannels: false,
                      );
                      if (result != null) {
                        if (!context.mounted) return;
                        ref
                            .read(activeBrandProvider.notifier)
                            .select(result.brand);
                      }
                    },
                  ),
                  const SizedBox(height: KkfcSpace.s12),

                  // 2. Search field + Unavailable button with tactile press feedback
                  const CatalogSearchBar(),
                  if (visibleCount != null) ...[
                    const SizedBox(height: KkfcSpace.s8),
                    Text(
                      'Showing $visibleCount item${visibleCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontFamily: KkfcFonts.text,
                        fontSize: 13,
                        color: Color(0xFF586579),
                      ),
                    ),
                  ],
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
                  final isHidingUnavailable = ref.watch(
                    hideUnavailableProvider,
                  );

                  if (isSearching || isHidingUnavailable) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(KkfcSpace.s40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.search_off,
                                size: 40,
                                color: Color(0xFF76849A),
                              ),
                              const SizedBox(height: KkfcSpace.s12),
                              const Text(
                                'No items in this category or matching search',
                                style: TextStyle(
                                  fontFamily: KkfcFonts.ibmPlexSans,
                                  color: Color(0xFF586579),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: KkfcSpace.s12),
                              TextButton(
                                onPressed: () {
                                  ref.read(menuSearchProvider.notifier).clear();
                                  ref
                                      .read(hideUnavailableProvider.notifier)
                                      .set(false);
                                },
                                child: const Text('Clear filters'),
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
                              mainAxisExtent: 180.0,
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
      ),
    );
  }
}
