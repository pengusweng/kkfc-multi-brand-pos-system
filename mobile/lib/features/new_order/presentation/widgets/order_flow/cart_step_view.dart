import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/presentation/widgets/item_customization_dialog.dart';
import 'package:mobile/features/new_order/presentation/widgets/order_flow/cart_item_card.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

/// Step 2: The current order (cart panel) view for mobile phones matching the visual design.
class CartStepView extends ConsumerWidget {
  const CartStepView({
    super.key,
    required this.onContinue,
    this.onReturnToMenu,
  });

  final VoidCallback onContinue;
  final VoidCallback? onReturnToMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(cartProvider);
    final count = ref.watch(cartCountProvider);
    final total = ref.watch(cartTotalProvider);
    final channel = ref.watch(menuChannelProvider);

    final lineText = '${lines.length} line${lines.length == 1 ? '' : 's'}';
    final itemText = '$count item${count == 1 ? '' : 's'}';
    final subtitle = '$lineText · $itemText · ${channel.label}';

    return Column(
      children: [
        // Scrollable content area
        Expanded(
          child: lines.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.shopping_cart_outlined,
                          size: 48,
                          color: Color(0xFF76849A),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Your cart is empty',
                          style: TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: 18.0,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF19293E),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Choose delicious items from the menu.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: KkfcFonts.text,
                            fontSize: 14.0,
                            color: Color(0xFF586579),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (onReturnToMenu != null)
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF19293E),
                              side: const BorderSide(color: Color(0xFF76849A)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            onPressed: onReturnToMenu,
                            child: const Text('Back to Menu'),
                          ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  children: [
                    // Subtitle: "1 line · 2 items · Dine-in"
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: KkfcFonts.text,
                        fontSize: 13.5,
                        color: Color(0xFF586579),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Cart item cards
                    for (final line in lines) ...[
                      CartItemCard(
                        line: line,
                        channel: channel,
                        brandName: line.brandName,
                        onIncrement: () => ref
                            .read(cartProvider.notifier)
                            .incrementLine(line.id),
                        onDecrement: () => ref
                            .read(cartProvider.notifier)
                            .decrementLine(line.id),
                        onEdit: () => showItemCustomizationDialog(
                          context,
                          item: line.item,
                          channel: channel,
                          brandName: line.brandName,
                          editing: line,
                        ),
                        onRemove: () =>
                            ref.read(cartProvider.notifier).removeLine(line.id),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Subtotal & Total Summary Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: const Color(0xFFDDD6C9),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Subtotal row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Subtotal',
                                style: TextStyle(
                                  fontFamily: KkfcFonts.text,
                                  fontSize: 14.0,
                                  color: Color(0xFF586579),
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                child: Text(
                                  formatPeso(total),
                                  key: ValueKey('subtotal-$total'),
                                  style: const TextStyle(
                                    fontFamily: KkfcFonts.ibmPlexSans,
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF19293E),
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFEDE8DF),
                          ),
                          const SizedBox(height: 10),
                          // Total row
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
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                child: Text(
                                  formatPeso(total),
                                  key: ValueKey('total-$total'),
                                  style: const TextStyle(
                                    fontFamily: KkfcFonts.ibmPlexSans,
                                    fontSize: 18.0,
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
                        ],
                      ),
                    ),
                  ],
                ),
        ),

        // Bottom Action Bar
        if (lines.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: Material(
                  color: const Color(0xFFA8562A), // Burnished Copper
                  borderRadius: BorderRadius.circular(10.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10.0),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onContinue();
                    },
                    child: const Center(
                      child: Text(
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
            ),
          ),
      ],
    );
  }
}
