import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/presentation/widgets/item_customization_dialog.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';

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
  bool _cardPressed = false;
  bool _buttonPressed = false;
  bool _justAdded = false;
  Timer? _flashTimer;

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  Future<void> _onAdd(MenuItem item) async {
    HapticFeedback.lightImpact();

    final brand = ref.read(activeBrandProvider);
    final added = await showItemCustomizationDialog(
      context,
      item: item,
      channel: widget.channel,
      brandName: brand.name,
    );

    if (added == true && mounted) {
      setState(() {
        _buttonPressed = false;
        _justAdded = true;
      });

      _flashTimer?.cancel();
      _flashTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() => _justAdded = false);
        }
      });
    } else if (mounted) {
      setState(() {
        _buttonPressed = false;
        _cardPressed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final availability = item.availabilityFor(widget.channel);
    final orderable = availability == MenuAvailability.available;
    final price = formatPeso(item.priceFor(widget.channel));

    return AnimatedScale(
      scale: _cardPressed ? KkfcMotion.pressScale : 1.0,
      duration: KkfcMotion.durPress,
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: orderable ? () => _onAdd(item) : null,
          onTapDown: (_) => setState(() => _cardPressed = true),
          onTapCancel: () => setState(() => _cardPressed = false),
          onTapUp: (_) => setState(() => _cardPressed = false),
          child: AnimatedContainer(
            duration: KkfcMotion.durMicro,
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: _cardPressed
                    ? const Color(0xFF76849A)
                    : const Color(0xFFDDD6C9),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: _cardPressed ? 0.08 : 0.03,
                  ),
                  blurRadius: _cardPressed ? 10 : 6,
                  offset: Offset(0, _cardPressed ? 4 : 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Item name and availability badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
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
                        ),
                        if (!orderable) ...[
                          const SizedBox(width: 8),
                          _AvailabilityBadge(availability),
                        ],
                      ],
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
                  ],
                ),
                const SizedBox(height: 8),

                // Bottom row: Price and Add button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Animated Price for channel changes
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
                        price,
                        key: ValueKey('price-${widget.item.id}-$price'),
                        style: const TextStyle(
                          fontFamily: KkfcFonts.ibmPlexSans,
                          fontSize: 18.0,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF19293E),
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),

                    // Tactile Add Button with quick confirmation pop
                    AnimatedScale(
                      scale: _buttonPressed ? 0.92 : (_justAdded ? 1.05 : 1.0),
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOutCubic,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8.0),
                          onTapDown: (_) => setState(() {
                            _cardPressed = true;
                            _buttonPressed = true;
                          }),
                          onTapCancel: () => setState(() {
                            _cardPressed = false;
                            _buttonPressed = false;
                          }),
                          onTapUp: (_) => setState(() {
                            _cardPressed = false;
                          }),
                          onTap: orderable ? () => _onAdd(item) : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _justAdded
                                  ? const Color(
                                      0xFFA8562A,
                                    ) // Burnished copper flash
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(
                                color: _justAdded
                                    ? const Color(0xFFA8562A)
                                    : const Color(0xFF43536A),
                                width: 1.0,
                              ),
                              boxShadow: _justAdded
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFA8562A)
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 150),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: _justAdded
                                  ? const Row(
                                      key: ValueKey('added'),
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Added',
                                          style: TextStyle(
                                            fontFamily: KkfcFonts.ibmPlexSans,
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Row(
                                      key: ValueKey('add'),
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
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge(this.availability);
  final MenuAvailability availability;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (availability) {
      MenuAvailability.stockout => (
        const Color(0xFFFEE4E2),
        const Color(0xFFB42318),
        'STOCKOUT',
      ),
      MenuAvailability.manualOff => (
        const Color(0xFFFEE4E2),
        const Color(0xFFB42318),
        'MANUAL OFF',
      ),
      MenuAvailability.inactive => (
        const Color(0xFFF2F4F7),
        const Color(0xFF475467),
        'INACTIVE',
      ),
      MenuAvailability.available => (
        Colors.transparent,
        Colors.transparent,
        '',
      ),
    };
    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: KkfcFonts.ibmPlexSans,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
