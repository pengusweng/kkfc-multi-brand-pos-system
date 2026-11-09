import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

/// Floating bottom order bar for phone layout matching the design.
class CartBar extends ConsumerWidget {
  const CartBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartCountProvider);
    final total = ref.watch(cartTotalProvider);

    return AnimatedSlide(
      offset: count > 0 ? Offset.zero : const Offset(0, 1.2),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: count > 0 ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Material(
              color: const Color(0xFFA8562A),
              borderRadius: BorderRadius.circular(10.0),
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.25),
              child: InkWell(
                borderRadius: BorderRadius.circular(10.0),
                // Don't make view order work first as instructed by user
                onTap: () {},
                child: Container(
                  height: 52.0,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: [Cart Icon]  "X items"
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$count item${count == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontFamily: KkfcFonts.ibmPlexSans,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      // Right: "View order · ₱XXX.XX"
                      Text(
                        'View order · ${formatPeso(total)}',
                        style: const TextStyle(
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
    );
  }
}
