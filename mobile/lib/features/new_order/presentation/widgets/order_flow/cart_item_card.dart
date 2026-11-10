import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';

/// Card representing a single cart item on mobile matching the design.
class CartItemCard extends StatelessWidget {
  const CartItemCard({
    super.key,
    required this.line,
    required this.channel,
    required this.brandName,
    required this.onIncrement,
    required this.onDecrement,
    required this.onEdit,
    required this.onRemove,
  });

  final CartLine line;
  final MenuChannel channel;
  final String brandName;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  String _formatModifiers(CartLine line) {
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
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final modifiers = _formatModifiers(line);
    final unitPrice = line.unitCentavos(channel);
    final lineTotal = line.totalCentavos(channel);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFDDD6C9), width: 1.0),
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
        children: [
          // Row 1: Item Name and Line Total
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  line.item.name,
                  style: const TextStyle(
                    fontFamily: KkfcFonts.ibmPlexSans,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF19293E),
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, -0.2),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Text(
                  formatPeso(lineTotal),
                  key: ValueKey('total-$lineTotal'),
                  style: const TextStyle(
                    fontFamily: KkfcFonts.ibmPlexSans,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF19293E),
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Row 2: Brand Tag and Unit Price
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF0F4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  brandName,
                  style: const TextStyle(
                    fontFamily: KkfcFonts.text,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF43536A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${formatPeso(unitPrice)} each',
                style: const TextStyle(
                  fontFamily: KkfcFonts.text,
                  fontSize: 13.0,
                  color: Color(0xFF586579),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),

          // Row 3: Modifiers list
          if (modifiers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              modifiers,
              style: const TextStyle(
                fontFamily: KkfcFonts.text,
                fontSize: 13.0,
                height: 1.35,
                color: Color(0xFF586579),
              ),
            ),
          ],

          // Kitchen Note if present
          if (line.kitchenNote != null && line.kitchenNote!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF4E2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFE8D3A7)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.edit_note,
                    size: 14,
                    color: Color(0xFF855B14),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      line.kitchenNote!,
                      style: const TextStyle(
                        fontFamily: KkfcFonts.text,
                        fontStyle: FontStyle.italic,
                        fontSize: 12.0,
                        color: Color(0xFF855B14),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Row 4: Controls ([-], qty, [+], [Edit], Remove)
          Row(
            children: [
              // Stepper: -
              _ButtonContainer(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onDecrement();
                },
                child: const Icon(
                  Icons.remove,
                  size: 16,
                  color: Color(0xFF19293E),
                ),
              ),
              SizedBox(
                width: 34,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                      child: child,
                    ),
                    child: Text(
                      '${line.quantity}',
                      key: ValueKey('qty-${line.quantity}'),
                      style: const TextStyle(
                        fontFamily: KkfcFonts.ibmPlexSans,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF19293E),
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
              // Stepper: +
              _ButtonContainer(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onIncrement();
                },
                child: const Icon(
                  Icons.add,
                  size: 16,
                  color: Color(0xFF19293E),
                ),
              ),
              const SizedBox(width: 12),

              // Edit button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8.0),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onEdit();
                  },
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: const Color(0xFF76849A),
                        width: 1.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        fontFamily: KkfcFonts.ibmPlexSans,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF19293E),
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Remove button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(6.0),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onRemove();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Text(
                      'Remove',
                      style: TextStyle(
                        fontFamily: KkfcFonts.ibmPlexSans,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB3261E),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ButtonContainer extends StatelessWidget {
  const _ButtonContainer({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: const Color(0xFF76849A), width: 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8.0),
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }
}
