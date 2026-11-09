import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

class MenuItemCard extends ConsumerStatefulWidget {
  const MenuItemCard({
    super.key,
    required this.item,
    required this.channel,
    this.compact = false,
  });

  final MenuItem item;
  final MenuChannel channel;
  final bool compact;

  @override
  ConsumerState<MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends ConsumerState<MenuItemCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final availability = item.availabilityFor(widget.channel);
    final orderable = availability == MenuAvailability.available;
    final price = formatPeso(item.priceFor(widget.channel));

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Item name
            Text(
              item.name,
              maxLines: widget.compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: KkfcFonts.ibmPlexSans,
                fontSize: 16.0,
                fontWeight: FontWeight.w700,
                color: Color(0xFF19293E),
              ),
            ),
            const SizedBox(height: 6),

            // Item description
            if (item.description.isNotEmpty)
              Text(
                item.description,
                maxLines: widget.compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.0,
                  height: 1.35,
                  color: Color(0xFF586579),
                ),
              ),
            const SizedBox(height: 16),

            // Bottom row: Price and Add button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontFamily: KkfcFonts.ibmPlexSans,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF19293E),
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8.0),
                    onTapDown: (_) => setState(() => _pressed = true),
                    onTapCancel: () => setState(() => _pressed = false),
                    onTap: orderable
                        ? () {
                            setState(() => _pressed = false);
                            ref.read(cartProvider.notifier).add(item);
                          }
                        : null,
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: const Color(0xFF43536A),
                          width: 1.0,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add,
                            size: 16,
                            color: Color(0xFF19293E),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Add',
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
