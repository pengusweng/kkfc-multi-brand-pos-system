import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

/// Step 4: Review order details and line items before confirming.
class ReviewOrderStepView extends ConsumerWidget {
  const ReviewOrderStepView({super.key, required this.onConfirm});

  final VoidCallback onConfirm;

  String _formatModifiers(CartLine line, String brandName) {
    final parts = <String>[];
    for (final g in line.item.modifierGroups) {
      final selId = line.selections[g.id] ?? g.defaultOptionId;
      if (g.isAddOn && selId != ModifierGroup.addOnOn) continue;

      final opt = g.optionById(selId);
      if (opt.priceDeltaCentavos != 0) {
        final delta = opt.priceDeltaCentavos;
        final sign = delta > 0 ? '+' : '';
        final str = (delta % 100 == 0)
            ? '₱${delta ~/ 100}'
            : formatPeso(delta.abs());
        parts.add('${opt.label} ($sign$str)');
      } else {
        parts.add(opt.label);
      }
    }

    final mods = parts.join(', ');
    if (brandName.isNotEmpty) {
      return mods.isNotEmpty ? '$brandName · $mods' : brandName;
    }
    return mods;
  }

  String _paymentNote(MenuChannel channel) {
    switch (channel) {
      case MenuChannel.dineIn:
        return 'Guests pay after eating. Sending does not wait for payment.';
      case MenuChannel.takeaway:
        return 'Guests pay before eating or when claiming takeaway order.';
      case MenuChannel.grabFood:
      case MenuChannel.foodpanda:
        return 'Paid through delivery platform.';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channel = ref.watch(menuChannelProvider);
    final reference = ref.watch(orderReferenceProvider);
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    final itemCount = ref.watch(cartCountProvider);
    final activeBrand = ref.watch(assignedBrandProvider).asData?.value;
    final brandName = activeBrand?.name ?? 'Gamcheon';

    final lineCount = cart.length;

    return Column(
      children: [
        Expanded(
          child: Container(
            color: const Color(0xFFF7F4EE),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Info Banner
                Container(
                  margin: const EdgeInsets.only(bottom: 14.0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 12.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F1FC),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: const Color(0xFFB9D7F9),
                      width: 1.0,
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF19293E),
                        size: 20.0,
                      ),
                      SizedBox(width: 10.0),
                      Expanded(
                        child: Text(
                          'Not sent yet. Please review carefully before confirming.',
                          style: TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF19293E),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Card 1: Channel & Reference Meta Card
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: const Color(0xFFDDD6C9),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Channel Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Channel',
                            style: TextStyle(
                              fontFamily: KkfcFonts.text,
                              fontSize: 15.0,
                              color: Color(0xFF586579),
                            ),
                          ),
                          Text(
                            channel.label,
                            style: const TextStyle(
                              fontFamily: KkfcFonts.ibmPlexSans,
                              fontSize: 15.0,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF19293E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Table / Reference Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            channel == MenuChannel.dineIn
                                ? 'Table'
                                : 'Reference',
                            style: const TextStyle(
                              fontFamily: KkfcFonts.text,
                              fontSize: 15.0,
                              color: Color(0xFF586579),
                            ),
                          ),
                          Text(
                            reference.isNotEmpty ? reference : 'Table 7',
                            style: const TextStyle(
                              fontFamily: KkfcFonts.ibmPlexSans,
                              fontSize: 15.0,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF19293E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Payment Status Row
                      Row(
                        children: [
                          const Text(
                            'Payment status ',
                            style: TextStyle(
                              fontFamily: KkfcFonts.ibmPlexSans,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF19293E),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDF1F5),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 14,
                                  color: Color(0xFF586579),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Unpaid',
                                  style: TextStyle(
                                    fontFamily: KkfcFonts.ibmPlexSans,
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF586579),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Text(
                        _paymentNote(channel),
                        style: const TextStyle(
                          fontFamily: KkfcFonts.text,
                          fontSize: 13.5,
                          color: Color(0xFF586579),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Card 2: Order Items & Pricing Card
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: const Color(0xFFDDD6C9),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: "1 line · 2 items"
                      Text(
                        '$lineCount line${lineCount == 1 ? '' : 's'} · $itemCount item${itemCount == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontFamily: KkfcFonts.ibmPlexSans,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF19293E),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Items List
                      for (var idx = 0; idx < cart.length; idx++) ...[
                        if (idx > 0) const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // "2×"
                            SizedBox(
                              width: 26,
                              child: Text(
                                '${cart[idx].quantity}×',
                                style: const TextStyle(
                                  fontFamily: KkfcFonts.ibmPlexSans,
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF19293E),
                                ),
                              ),
                            ),

                            // Name & Modifiers
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cart[idx].item.name,
                                    style: const TextStyle(
                                      fontFamily: KkfcFonts.ibmPlexSans,
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF19293E),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _formatModifiers(cart[idx], brandName),
                                    style: const TextStyle(
                                      fontFamily: KkfcFonts.text,
                                      fontSize: 13.0,
                                      color: Color(0xFF586579),
                                      height: 1.3,
                                    ),
                                  ),
                                  if (cart[idx].kitchenNote != null &&
                                      cart[idx].kitchenNote!.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      'Note: "${cart[idx].kitchenNote}"',
                                      style: const TextStyle(
                                        fontFamily: KkfcFonts.text,
                                        fontSize: 12.0,
                                        fontStyle: FontStyle.italic,
                                        color: Color(0xFF586579),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Total
                            Text(
                              formatPeso(cart[idx].totalCentavos(channel)),
                              style: const TextStyle(
                                fontFamily: KkfcFonts.ibmPlexSans,
                                fontSize: 15.0,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF19293E),
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFEDE8DF),
                      ),
                      const SizedBox(height: 14),

                      // Subtotal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Subtotal',
                            style: TextStyle(
                              fontFamily: KkfcFonts.text,
                              fontSize: 15.0,
                              color: Color(0xFF586579),
                            ),
                          ),
                          Text(
                            formatPeso(total),
                            style: const TextStyle(
                              fontFamily: KkfcFonts.ibmPlexSans,
                              fontSize: 15.0,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF586579),
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Total
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
                          Text(
                            formatPeso(total),
                            style: const TextStyle(
                              fontFamily: KkfcFonts.ibmPlexSans,
                              fontSize: 18.0,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF19293E),
                              fontFeatures: [FontFeature.tabularFigures()],
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
        ),

        // Bottom Action Bar: "Confirm and send"
        Container(
          color: const Color(0xFFF7F3EC),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 52,
              width: double.infinity,
              child: Material(
                color: const Color(0xFFA8562A),
                borderRadius: BorderRadius.circular(10.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10.0),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onConfirm();
                  },
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant,
                          color: Colors.white,
                          size: 18.0,
                        ),
                        SizedBox(width: 8.0),
                        Text(
                          'Confirm and send',
                          style: TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: 16.0,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
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
