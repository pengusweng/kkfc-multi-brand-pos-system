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

class _ResponsiveMenuLayout extends ConsumerWidget {
  const _ResponsiveMenuLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= _kWideBreakpoint;
    final cartCount = ref.watch(cartCountProvider);

    return Column(
      children: [
        // App header
        AppHeader(title: 'Orders', compact: !isWide),

        // Main body
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left / Center catalog
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        color: const Color(0xFFF7F3EC), // Canvas background
                        child: _MenuCatalogView(
                          isWide: isWide,
                          bottomPadding: (!isWide && cartCount > 0)
                              ? 72.0
                              : 16.0,
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

              // Tablet / Desktop-only right cart panel
              if (isWide) const SizedBox(width: 380.0, child: CartPanel()),
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
  bool _searchFocused = false;
  bool _unavailablePressed = false;

  final List<String> _categories = const [
    'All',
    'Rice bowls',
    'Sets',
    'Snacks',
  ];

  int _slideDirection = 1;
  String? _lastBrandId;
  String _lastCategory = 'All';
  int _categorySlideDirection = 1;

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
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(menuSearchProvider, (_, query) {
      if (_searchController.text != query) {
        _searchController.text = query;
      }
    });

    final activeBrand = ref.watch(activeBrandProvider);
    final assignedBrands = ref.watch(assignedBrandsProvider);
    final selectedChannel = ref.watch(menuChannelProvider);
    final selectedCategory = ref.watch(menuCategoryProvider);
    final visibleItems = ref.watch(visibleMenuItemsProvider);

    // Track sliding animation direction for brand switching
    var isBrandSwitch = false;
    if (_lastBrandId != null && _lastBrandId != activeBrand.id) {
      final oldIndex = assignedBrands.indexWhere((b) => b.id == _lastBrandId);
      final newIndex = assignedBrands.indexWhere((b) => b.id == activeBrand.id);
      _slideDirection = (newIndex >= oldIndex) ? 1 : -1;
      isBrandSwitch = true;
    }
    _lastBrandId = activeBrand.id;

    // Track category switch animation
    if (!isBrandSwitch && _lastCategory != selectedCategory) {
      final oldIndex = _categories.indexOf(_lastCategory);
      final newIndex = _categories.indexOf(selectedCategory);
      _categorySlideDirection = (newIndex >= oldIndex) ? 1 : -1;
    }
    _lastCategory = selectedCategory;

    final currentSlide = isBrandSwitch
        ? _slideDirection
        : _categorySlideDirection;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              widget.isWide ? 20.0 : 16.0,
              16.0,
              widget.isWide ? 20.0 : 16.0,
              12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Brands segmented tabs with sliding animation
                _BrandSegmentedBar(
                  brands: assignedBrands,
                  selectedBrand: activeBrand,
                  onSelect: (b) =>
                      ref.read(activeBrandProvider.notifier).select(b),
                ),
                const SizedBox(height: 10),

                // 2. Channel segmented tabs with sliding indicator and repricing trigger
                _ChannelSegmentedBar(
                  selectedChannel: selectedChannel,
                  onSelect: _onChannelSelected,
                ),
                const SizedBox(height: 12),

                // 3. Search field + Unavailable button
                Row(
                  children: [
                    // Search bar with animated focus ring
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOut,
                        height: 44.0,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
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
                          onChanged: ref.read(menuSearchProvider.notifier).set,
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
                                    onPressed: () {
                                      _searchController.clear();
                                      ref
                                          .read(menuSearchProvider.notifier)
                                          .clear();
                                    },
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
                    const SizedBox(width: 10),

                    // Unavailable button with tactile press
                    AnimatedScale(
                      scale: _unavailablePressed ? KkfcMotion.pressScale : 1.0,
                      duration: KkfcMotion.durPress,
                      curve: Curves.easeOut,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8.0),
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
                              borderRadius: BorderRadius.circular(8.0),
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
                const SizedBox(height: 14),

                // 4. Category chips filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final cat in _categories) ...[
                        _CategoryChip(
                          label: cat,
                          selected: selectedCategory == cat,
                          onTap: () =>
                              ref.read(menuCategoryProvider.notifier).set(cat),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 5. Menu Items Grid / List with sliding animation on brand switch
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            widget.isWide ? 20.0 : 16.0,
            4.0,
            widget.isWide ? 20.0 : 16.0,
            widget.bottomPadding,
          ),
          sliver: visibleItems.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              ),
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
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.search_off,
                            size: 40,
                            color: Color(0xFF76849A),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No items in this category or matching search',
                            style: TextStyle(
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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final inAnimation =
                        Tween<Offset>(
                          begin: Offset(currentSlide * 0.08, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        );

                    return SlideTransition(
                      position: inAnimation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(
                      'catalog-${activeBrand.id}-$selectedCategory-${ref.watch(menuSearchProvider)}',
                    ),
                    child: widget.isWide
                        ? GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
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
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12.0),
                            itemBuilder: (context, index) => MenuItemCard(
                              item: items[index],
                              channel: selectedChannel,
                              compact: true,
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Brand segmented bar with sliding indicator animation
class _BrandSegmentedBar extends StatelessWidget {
  const _BrandSegmentedBar({
    required this.brands,
    required this.selectedBrand,
    required this.onSelect,
  });

  final List<AssignedBrand> brands;
  final AssignedBrand selectedBrand;
  final ValueChanged<AssignedBrand> onSelect;

  @override
  Widget build(BuildContext context) {
    if (brands.isEmpty) return const SizedBox.shrink();

    final selectedIndex = brands.indexWhere((b) => b.id == selectedBrand.id);
    final safeIndex = selectedIndex == -1 ? 0 : selectedIndex;

    return Container(
      height: 44.0,
      padding: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEEE8DC), // Canvas sunken ground
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / brands.length;

          return Stack(
            children: [
              // Smooth sliding pill indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                left: safeIndex * tabWidth,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D2940), // Selected Navy
                    borderRadius: BorderRadius.circular(6.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),

              // Brand labels row
              Row(
                children: [
                  for (var i = 0; i < brands.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onSelect(brands[i]),
                        child: Container(
                          alignment: Alignment.center,
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontFamily: KkfcFonts.ibmPlexSans,
                              fontSize: 13.5,
                              fontWeight: i == safeIndex
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: i == safeIndex
                                  ? Colors.white
                                  : const Color(0xFF19293E),
                            ),
                            child: Text(
                              brands[i].name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Channel segmented bar with sliding indicator animation
class _ChannelSegmentedBar extends StatelessWidget {
  const _ChannelSegmentedBar({
    required this.selectedChannel,
    required this.onSelect,
  });

  final MenuChannel selectedChannel;
  final ValueChanged<MenuChannel> onSelect;

  @override
  Widget build(BuildContext context) {
    final channels = MenuChannel.values;
    final selectedIndex = channels.indexOf(selectedChannel);
    final safeIndex = selectedIndex == -1 ? 0 : selectedIndex;

    return Container(
      height: 44.0,
      padding: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEEE8DC), // Canvas sunken ground
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / channels.length;

          return Stack(
            children: [
              // Smooth sliding pill indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                left: safeIndex * tabWidth,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D2940), // Selected Navy
                    borderRadius: BorderRadius.circular(6.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),

              // Channel labels row
              Row(
                children: [
                  for (var i = 0; i < channels.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onSelect(channels[i]),
                        child: Container(
                          alignment: Alignment.center,
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontFamily: KkfcFonts.ibmPlexSans,
                              fontSize: 13.5,
                              fontWeight: i == safeIndex
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: i == safeIndex
                                  ? Colors.white
                                  : const Color(0xFF19293E),
                            ),
                            child: Text(
                              channels[i].label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Category pill chip matching the design with tactile press feedback
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
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: widget.selected
                ? const Color(0xFF1D2940)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999.0), // Full pill
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
