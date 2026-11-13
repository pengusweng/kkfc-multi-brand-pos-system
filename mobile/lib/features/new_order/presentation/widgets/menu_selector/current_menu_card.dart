import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/core/models/brand_models.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';

/// "Current menu" selector card matching the visual design:
/// Label: "Current menu"
/// Button: `[ Gamcheon · Dine-in                     > ]`
class CurrentMenuCard extends StatelessWidget {
  const CurrentMenuCard({
    super.key,
    required this.brand,
    required this.channel,
    required this.onTap,
    this.showChannel = true,
  });

  final AssignedBrand brand;
  final MenuChannel channel;
  final VoidCallback onTap;
  final bool showChannel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label: "Current menu"
        const Text(
          'Current menu',
          style: TextStyle(
            fontFamily: KkfcFonts.ibmPlexSans,
            fontSize: 13.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFF586579),
          ),
        ),
        const SizedBox(height: 6.0),

        // Selector button card
        Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey('current-menu-selector-card'),
            borderRadius: BorderRadius.circular(10.0),
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: Ink(
              height: 48.0,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: const Color(0xFFDDD6C9), width: 1.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      showChannel
                          ? '${brand.name} · ${channel.label}'
                          : brand.name,
                      style: const TextStyle(
                        fontFamily: KkfcFonts.ibmPlexSans,
                        fontSize: 15.0,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF19293E),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 22.0,
                    color: Color(0xFF19293E),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
