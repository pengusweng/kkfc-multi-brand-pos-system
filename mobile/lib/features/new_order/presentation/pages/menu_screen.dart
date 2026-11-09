import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/routes.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/core/models/brand_models.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/presentation/widgets/cart_bar.dart';
import 'package:mobile/features/new_order/presentation/widgets/cart_panel/cart_panel.dart';
import 'package:mobile/features/new_order/presentation/widgets/menu_item_card.dart';
import 'package:mobile/features/new_order/presentation/widgets/menu_selector/choose_menu_modal.dart';
import 'package:mobile/features/new_order/presentation/widgets/menu_selector/current_menu_card.dart';
import 'package:mobile/features/new_order/presentation/widgets/menu_states.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';
import 'package:mobile/shared/widgets/app_header.dart';
import 'package:mobile/shared/widgets/kkfc_scaffold.dart';

/// Screen breakpoint for wide tablet/desktop layout vs single-column phone layout.
const double _kWideBreakpoint = 850.0;

/// The revamped New Order / Orders screen matching the modern KKFC POS design.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const KkfcScaffold(body: _ResponsiveMenuLayout());
  }
}

class _ResponsiveMenuLayout extends ConsumerStatefulWidget {
  const _ResponsiveMenuLayout();

  @override
  ConsumerState<_ResponsiveMenuLayout> createState() =>
      _ResponsiveMenuLayoutState();
}

class _ResponsiveMenuLayoutState extends ConsumerState<_ResponsiveMenuLayout>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _catalogFade;
  late final Animation<Offset> _catalogSlide;
  late final Animation<double> _cartPanelFade;
  late final Animation<Offset> _cartPanelSlide;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    // Choreographed entrance:
    // 1. App Header drops down subtly and fades in
    _headerFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.60, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0.0, -0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
    ));

    // 2. Catalog view rises up smoothly and dissolves in
    _catalogFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.10, 0.85, curve: Curves.easeOut),
    );
    _catalogSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.10, 0.90, curve: Curves.easeOutCubic),
    ));

    // 3. Tablet/Desktop Cart Panel glides in from the right edge
    _cartPanelFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.18, 1.0, curve: Curves.easeOut),
    );
    _cartPanelSlide = Tween<Offset>(
      begin: const Offset(0.06, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.18, 1.0, curve: Curves.easeOutCubic),
    ));

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= _kWideBreakpoint;
    final cartCount = ref.watch(cartCountProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    // Safe clearance when floating CartBar is present on phone
    final bottomPadding = (!isWide && cartCount > 0)
        ? (80.0 + bottomInset)
        : (16.0 + bottomInset);

    return Column(
      children: [
        // App header with entrance transition
        SlideTransition(
          position: _headerSlide,
          child: FadeTransition(
            opacity: _headerFade,
            child: AppHeader(title: 'Orders', compact: !isWide),
          ),
        ),

        // Main body with choreographed entrance
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left / Center catalog
              Expanded(
                child: SlideTransition(
                  position: _catalogSlide,
                  child: FadeTransition(
                    opacity: _catalogFade,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            color: const Color(0xFFF7F3EC), // Canvas ground
                            child: _MenuCatalogView(
                              isWide: isWide,
                              bottomPadding: bottomPadding,
                            ),
                          ),
                        ),

                        // Phone-only floating cart bar
                        if (!isWide)
                          const Align(
                            alignment: Alignment.bottomCenter,
                            child: CartBar(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Tablet / Desktop-only right cart panel
              if (isWide)
                SlideTransition(
                  position: _cartPanelSlide,
                  child: FadeTransition(
                    opacity: _cartPanelFade,
                    child: const SizedBox(width: 380.0, child: CartPanel()),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuCatalogView extends ConsumerStatefulWidget {
  const _MenuCatalogView({required this.isWide, required this.bottomPadding});

  final bool isWide;
  final double bottomPadding;

  @override
  ConsumerState<_MenuCatalogView> createState() => _MenuCatalogViewState();
}

class _MenuCatalogViewState extends ConsumerState<_MenuCatalogView> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _searchDebounce;
  bool _searchFocused = false;
  bool _unavailablePressed = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() => _searchFocused = _searchFocusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (mounted) {
        ref.read(menuSearchProvider.notifier).set(query);
      }
    });
  }

  void _onClearSearch() {
    _searchController.clear();
    _searchDebounce?.cancel();
    ref.read(menuSearchProvider.notifier).clear();
  }

  void _onChannelSelected(MenuChannel newChannel) {
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

  void _onMenuSwitched(AssignedBrand newBrand, MenuChannel newChannel) {
    final currentBrand = ref.read(activeBrandProvider);
    final currentChannel = ref.read(menuChannelProvider);

    if (newBrand.id != currentBrand.id) {
      ref.read(activeBrandProvider.notifier).select(newBrand);
    }

    if (newChannel != currentChannel) {
      _onChannelSelected(newChannel);
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
  Widget build(BuildContext context) {
    ref.listen<String>(menuSearchProvider, (_, query) {
      if (_searchController.text != query && !_searchFocusNode.hasFocus) {
        _searchController.text = query;
      }
    });

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
              widget.isWide ? KkfcSpace.s20 : KkfcSpace.s16,
              KkfcSpace.s16,
              widget.isWide ? KkfcSpace.s20 : KkfcSpace.s16,
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
                      _onMenuSwitched(result.brand, result.channel);
                    }
                  },
                ),
                const SizedBox(height: KkfcSpace.s12),

                // 2. Search field + Unavailable button with tactile press feedback
                Row(
                  children: [
                    // Search bar with animated focus ring & debounce
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOut,
                        height: 44.0,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(KkfcRadius.sm),
                          border: Border.all(
                            color: _searchFocused
                                ? const Color(0xFF1F66C9) // Focus Blue
                                : const Color(0xFF76849A),
                            width: _searchFocused ? 1.5 : 1.0,
                          ),
                          boxShadow: _searchFocused
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF1F66C9)
                                        .withValues(alpha: 0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: _onSearchChanged,
                          textAlignVertical: TextAlignVertical.center,
                          style: const TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: 14.0,
                            color: Color(0xFF19293E),
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Search',
                            hintStyle: const TextStyle(
                              fontFamily: KkfcFonts.ibmPlexSans,
                              fontSize: 14.0,
                              color: Color(0xFF76849A),
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 20,
                              color: Color(0xFF586579),
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: _onClearSearch,
                                  )
                                : null,
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: KkfcSpace.s12),

                    // Unavailable button with tactile press
                    AnimatedScale(
                      scale: _unavailablePressed ? KkfcMotion.pressScale : 1.0,
                      duration: KkfcMotion.durPress,
                      curve: Curves.easeOut,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(KkfcRadius.sm),
                          onTapDown: (_) =>
                              setState(() => _unavailablePressed = true),
                          onTapCancel: () =>
                              setState(() => _unavailablePressed = false),
                          onTapUp: (_) =>
                              setState(() => _unavailablePressed = false),
                          onTap: () => context.go(AppRoutes.availability),
                          child: Ink(
                            height: 44.0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14.0,
                            ),
                            decoration: BoxDecoration(
                              color: _unavailablePressed
                                  ? const Color(0xFFEEE8DC)
                                  : Colors.white,
                              borderRadius:
                                  BorderRadius.circular(KkfcRadius.sm),
                              border: Border.all(
                                color: _unavailablePressed
                                    ? const Color(0xFF19293E)
                                    : const Color(0xFF76849A),
                                width: 1.0,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.block_outlined,
                                  size: 18,
                                  color: Color(0xFF19293E),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Unavailable',
                                  style: TextStyle(
                                    fontFamily: KkfcFonts.ibmPlexSans,
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF19293E),
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
                const SizedBox(height: KkfcSpace.s12),

                // 3. Category chips filter (dynamically derived with 40dp touch target clearance)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final cat in categories) ...[
                        _CategoryChip(
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
            widget.isWide ? KkfcSpace.s20 : KkfcSpace.s16,
            KkfcSpace.s4,
            widget.isWide ? KkfcSpace.s20 : KkfcSpace.s16,
            widget.bottomPadding,
          ),
          sliver: visibleItems.when(
            loading: () => SliverToBoxAdapter(
              child: MenuGridSkeleton(isWide: widget.isWide),
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

                if (isSearching || isCategoryFiltered) {
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

              return widget.isWide
                  ? SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                        mainAxisExtent: 140.0,
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

/// Category pill chip matching the design with tactile press feedback & 40dp clearance
class _CategoryChip extends StatefulWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? KkfcMotion.pressScale : 1.0,
        duration: KkfcMotion.durPress,
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(
            horizontal: 18.0,
            vertical: 10.0,
          ),
          decoration: BoxDecoration(
            color: widget.selected
                ? const Color(0xFF1D2940)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(KkfcRadius.pill),
            border: widget.selected
                ? null
                : Border.all(color: const Color(0xFF76849A), width: 1.0),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF1D2940).withValues(alpha: 0.18),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: KkfcFonts.ibmPlexSans,
              fontSize: 14.0,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w600,
              color: widget.selected ? Colors.white : const Color(0xFF19293E),
            ),
          ),
        ),
      ),
    );
  }
}
