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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnimatedContainer(
      duration: reduceMotion ? Duration.zero : KkfcMotion.durLayout,
      curve: KkfcMotion.easeOut,
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
          : BoxDecoration(
              color: Colors.transparent,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(KkfcRadius.lg),
              ),
              border: Border.all(
                color: Colors.transparent,
                width: KkfcBorderWidth.thin,
              ),
            ),
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
          AnimatedSwitcher(
            duration: reduceMotion ? Duration.zero : KkfcMotion.durRelease,
            reverseDuration: reduceMotion ? Duration.zero : KkfcMotion.durExit,
            switchInCurve: KkfcMotion.easeSpring,
            switchOutCurve: KkfcMotion.easeIn,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: hasTickets
                ? Container(
                    key: ValueKey('lane-count-pill-${lane.name}-$count'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
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
                : Padding(
                    key: ValueKey('lane-count-zero-${lane.name}'),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: const Text(
                      '0',
                      style: TextStyle(
                        fontFamily: KkfcFonts.ibmPlexSans,
                        fontSize: KkfcTextSizes.textMd,
                        fontWeight: KkfcFontWeights.bold,
                        color: KkfcColors.neutral,
                        fontFeatures: tabularNumberFeatures,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
