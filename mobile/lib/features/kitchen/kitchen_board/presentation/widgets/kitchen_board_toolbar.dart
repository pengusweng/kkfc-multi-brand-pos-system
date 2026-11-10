import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/kitchen/kitchen_board/providers/kitchen_board_providers.dart';

/// Top operational subheader showing active ticket count, last updated time,
/// and the Refresh button.
class KitchenBoardToolbar extends StatelessWidget {
  const KitchenBoardToolbar({
    super.key,
    required this.activeCount,
    required this.updatedAt,
    required this.onRefresh,
    this.isRefreshing = false,
  });

  final int activeCount;
  final DateTime? updatedAt;
  final VoidCallback onRefresh;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final timeLabel = updatedAt != null
        ? KitchenBoardState.formatTimeOfDay(updatedAt!)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: KkfcSpace.s20,
        vertical: KkfcSpace.s8,
      ),
      decoration: const BoxDecoration(
        color: KkfcColors.surface,
        border: Border(
          bottom: BorderSide(
            color: KkfcColors.border,
            width: KkfcBorderWidth.thin,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: KkfcFonts.ibmPlexSans,
                  fontSize: KkfcTextSizes.textMd,
                  color: KkfcColors.ink2,
                  fontFeatures: tabularNumberFeatures,
                ),
                children: [
                  TextSpan(
                    text: '$activeCount active',
                    style: const TextStyle(
                      fontWeight: KkfcFontWeights.bold,
                      color: KkfcColors.ink,
                    ),
                  ),
                  if (timeLabel != null)
                    TextSpan(
                      text: ' · Updated $timeLabel',
                      style: const TextStyle(
                        fontWeight: KkfcFontWeights.regular,
                        color: KkfcColors.ink2,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: KkfcSpace.s12),
          OutlinedButton.icon(
            key: const ValueKey('kitchen-board-refresh-button'),
            onPressed: isRefreshing ? null : onRefresh,
            style: OutlinedButton.styleFrom(
              backgroundColor: KkfcColors.surface,
              foregroundColor: KkfcColors.ink,
              disabledForegroundColor: KkfcColors.ink3,
              minimumSize: const Size(0, KkfcTargets.webControl),
              padding: const EdgeInsets.symmetric(
                horizontal: KkfcSpace.s16,
                vertical: KkfcSpace.s8,
              ),
              side: const BorderSide(
                color: KkfcColors.borderStrong,
                width: KkfcBorderWidth.thin,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KkfcRadius.sm),
              ),
            ),
            icon: isRefreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: KkfcColors.ink,
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: KkfcColors.ink,
                  ),
            label: const Text(
              'Refresh',
              style: TextStyle(
                fontFamily: KkfcFonts.ibmPlexSans,
                fontSize: KkfcTextSizes.textMd,
                fontWeight: KkfcFontWeights.bold,
                color: KkfcColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
