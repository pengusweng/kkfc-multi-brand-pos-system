import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/routes.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/presentation/customize_flow.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

/// Right-hand "Current order" panel for tablet and desktop views.
class CartPanel extends ConsumerStatefulWidget {
  const CartPanel({super.key});

  @override
  ConsumerState<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends ConsumerState<CartPanel> {
  bool _clearPressed = false;
  bool _continuePressed = false;

  @override
  Widget build(BuildContext context) {
    final lines = ref.watch(cartProvider);
    final brand = ref.watch(activeBrandProvider);
    final channel = ref.watch(menuChannelProvider);
    final total = ref.watch(cartTotalProvider);
    final count = ref.watch(cartCountProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFEDE8DF), width: 1.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current order',
                      style: TextStyle(
                        fontFamily: KkfcFonts.ibmPlexSans,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF19293E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        lines.isEmpty
                            ? channel.label
                            : '${lines.length} line${lines.length == 1 ? '' : 's'} · $count item${count == 1 ? '' : 's'} · ${channel.label}',
                        key: ValueKey(
                          'cart-header-subtitle-${lines.length}-$count-${channel.label}',
                        ),
                        style: const TextStyle(
                          fontSize: 13.0,
                          color: Color(0xFF586579),
                        ),
                      ),
                    ),
                  ],
                ),
                if (lines.isNotEmpty)
                  AnimatedScale(
                    scale: _clearPressed ? 0.94 : 1.0,
                    duration: const Duration(milliseconds: 90),
                    curve: Curves.easeOut,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8.0),
                        onTapDown: (_) => setState(() => _clearPressed = true),
                        onTapCancel: () =>
                            setState(() => _clearPressed = false),
                        onTapUp: (_) => setState(() => _clearPressed = false),
                        onTap: () {
                          ref.read(cartProvider.notifier).clear();
                        },
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: const Color(0xFFEDB3AF),
                              width: 1.0,
                            ),
                          ),
                          child: const Text(
                            'Clear',
                            style: TextStyle(
                              fontFamily: KkfcFonts.ibmPlexSans,
                              fontSize: 13.0,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFB3261E),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEDE8DF)),

          // Body: Empty State or Cart Items
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: lines.isEmpty
                  ? Center(
                      key: const ValueKey('empty-cart'),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 44,
                              color: Color(0xFF76849A),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No items yet. Choose an item from the\nmenu.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15.0,
                                height: 1.4,
                                color: Color(0xFF586579),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      key: const ValueKey('cart-items'),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: lines.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 24, color: Color(0xFFEDE8DF)),
                      itemBuilder: (context, index) {
                        final line = lines[index];
                        final modifiers = line.modifierSummary;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Line title and line total
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      line.item.name,
                                      style: const TextStyle(
                                        fontFamily: KkfcFonts.ibmPlexSans,
                                        fontSize: 15.0,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF19293E),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    transitionBuilder: (child, animation) {
                                      return SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.2),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      formatPeso(line.totalCentavos(channel)),
                                      key: ValueKey(
                                        'line-total-${line.id}-${line.totalCentavos(channel)}',
                                      ),
                                      style: const TextStyle(
                                        fontFamily: KkfcFonts.ibmPlexSans,
                                        fontSize: 15.0,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF19293E),
                                        fontFeatures: [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              // Brand badge and unit price
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEDF0F4),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      brand.name,
                                      style: const TextStyle(
                                        fontSize: 11.0,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF43536A),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${formatPeso(line.unitCentavos(channel))} each',
                                    style: const TextStyle(
                                      fontSize: 12.0,
                                      color: Color(0xFF586579),
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Modifiers summary
                              if (modifiers.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  modifiers.join(' · '),
                                  style: const TextStyle(
                                    fontSize: 12.0,
                                    color: Color(0xFF586579),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),

                              // Controls: [-] [qty] [+] [Edit] [Remove]
                              Row(
                                children: [
                                  // Stepper: -
                                  _QtyButton(
                                    icon: Icons.remove,
                                    onTap: () => ref
                                        .read(cartProvider.notifier)
                                        .decrementLine(line.id),
                                  ),
                                  SizedBox(
                                    width: 32,
                                    child: Center(
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        transitionBuilder: (child, animation) {
                                          return ScaleTransition(
                                            scale: animation,
                                            child: FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: Text(
                                          '${line.quantity}',
                                          key: ValueKey(
                                            'qty-${line.id}-${line.quantity}',
                                          ),
                                          style: const TextStyle(
                                            fontFamily: KkfcFonts.ibmPlexSans,
                                            fontSize: 15.0,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF19293E),
                                            fontFeatures: [
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Stepper: +
                                  _QtyButton(
                                    icon: Icons.add,
                                    onTap: () => ref
                                        .read(cartProvider.notifier)
                                        .incrementLine(line.id),
                                  ),
                                  const SizedBox(width: 8),

                                  // Edit button
                                  _EditButton(
                                    onTap: () => openCustomize(
                                      context,
                                      ref,
                                      item: line.item,
                                      editing: line,
                                    ),
                                  ),
                                  const Spacer(),

                                  // Remove button
                                  TextButton(
                                    onPressed: () => ref
                                        .read(cartProvider.notifier)
                                        .removeLine(line.id),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFFB3261E),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Remove',
                                      style: TextStyle(
                                        fontFamily: KkfcFonts.ibmPlexSans,
                                        fontSize: 13.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),

          // Footer (Subtotal, Total, Continue button)
          if (lines.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFEDE8DF)),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Color(0xFF586579),
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.25),
                              end: Offset.zero,
                            ).animate(animation),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          formatPeso(total),
                          key: ValueKey('cart-subtotal-$total'),
                          style: const TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF19293E),
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontFamily: KkfcFonts.ibmPlexSans,
                          fontSize: 18.0,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF19293E),
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.25),
                              end: Offset.zero,
                            ).animate(animation),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          formatPeso(total),
                          key: ValueKey('cart-total-$total'),
                          style: const TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: 18.0,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF19293E),
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Listener(
                    onPointerDown: (_) =>
                        setState(() => _continuePressed = true),
                    onPointerUp: (_) =>
                        setState(() => _continuePressed = false),
                    onPointerCancel: (_) =>
                        setState(() => _continuePressed = false),
                    child: AnimatedScale(
                      scale: _continuePressed ? KkfcMotion.pressScale : 1.0,
                      duration: KkfcMotion.durPress,
                      curve: Curves.easeOut,
                      child: SizedBox(
                        width: double.infinity,
                        height: 50.0,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(
                              0xFFA8562A,
                            ), // Burnished copper
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          onPressed: () {
                            context.go(AppRoutes.orderEntry);
                          },
                          child: const Text(
                            'Continue to order details',
                            style: TextStyle(
                              fontFamily: KkfcFonts.ibmPlexSans,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EditButton extends StatefulWidget {
  const _EditButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_EditButton> createState() => _EditButtonState();
}

class _EditButtonState extends State<_EditButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.94 : 1.0,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8.0),
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _pressed ? const Color(0xFFEEE8DC) : Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: _pressed
                    ? const Color(0xFF19293E)
                    : const Color(0xFF76849A),
                width: 1.0,
              ),
            ),
            child: const Text(
              'Edit',
              style: TextStyle(
                fontFamily: KkfcFonts.ibmPlexSans,
                fontSize: 13.0,
                fontWeight: FontWeight.w600,
                color: Color(0xFF19293E),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QtyButton extends StatefulWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_QtyButton> createState() => _QtyButtonState();
}

class _QtyButtonState extends State<_QtyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.90 : 1.0,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6.0),
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: Ink(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _pressed ? const Color(0xFFEEE8DC) : Colors.white,
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(
                color: _pressed
                    ? const Color(0xFF19293E)
                    : const Color(0xFF76849A),
                width: 1.0,
              ),
            ),
            child: Icon(widget.icon, size: 16, color: const Color(0xFF19293E)),
          ),
        ),
      ),
    );
  }
}
