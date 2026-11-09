import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/new_order/presentation/widgets/cart_bar.dart';
import 'package:mobile/features/new_order/presentation/widgets/cart_panel/cart_panel.dart';
import 'package:mobile/features/new_order/presentation/widgets/catalog/menu_catalog_view.dart';
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
                            child: MenuCatalogView(
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
