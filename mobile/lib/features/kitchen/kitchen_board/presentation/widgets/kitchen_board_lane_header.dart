import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_lane.dart';

/// Renders the status header at the top of a [KitchenBoardLane] column.
///
/// Active lanes (`count > 0`) display a tinted header bar with a bordered pill
/// count badge; empty lanes (`count == 0`) blend into the sunken lane canvas
/// with a plain numeric count matching the KDS design spec.
class KitchenBoardLaneHeader extends StatelessWidget {
  const KitchenBoardLaneHeader({
    super.key,
    required this.lane,
    required this.count,
  });

  final KitchenBoardLane lane;
  final int count;

  @override
  Widget build(BuildContext context) {
    final hasTickets = count > 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KkfcSpace.s12,
        vertical: 10.0,
      ),
      decoration: hasTickets
          ? BoxDecoration(
              color: lane.headerBackground,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(KkfcRadius.lg),
              ),
              border: Border.all(
                color: lane.headerBorder,
                width: KkfcBorderWidth.thin,
              ),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(lane.icon, size: 18, color: lane.headerForeground),
                const SizedBox(width: KkfcSpace.s8),
                Flexible(
                  child: Text(
                    lane.title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: KkfcFonts.ibmPlexSans,
                      fontSize: KkfcTextSizes.textBase,
                      fontWeight: KkfcFontWeights.bold,
                      color: lane.headerForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: KkfcSpace.s8),
          if (hasTickets)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: KkfcColors.surface,
                borderRadius: BorderRadius.circular(KkfcRadius.pill),
                border: Border.all(
                  color: lane.headerBorder,
                  width: KkfcBorderWidth.thin,
                ),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontFamily: KkfcFonts.ibmPlexSans,
                  fontSize: KkfcTextSizes.textSm,
                  fontWeight: KkfcFontWeights.bold,
                  color: lane.badgeTextColor,
                  fontFeatures: tabularNumberFeatures,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '0',
                style: const TextStyle(
                  fontFamily: KkfcFonts.ibmPlexSans,
                  fontSize: KkfcTextSizes.textMd,
                  fontWeight: KkfcFontWeights.bold,
                  color: KkfcColors.neutral,
                  fontFeatures: tabularNumberFeatures,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
