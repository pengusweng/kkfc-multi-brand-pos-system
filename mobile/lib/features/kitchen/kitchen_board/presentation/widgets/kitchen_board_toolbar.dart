import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/kitchen/kitchen_board/providers/kitchen_board_providers.dart';

/// Top operational subheader showing active ticket count, last updated time,
/// and the Refresh button.
class KitchenBoardToolbar extends StatefulWidget {
  const KitchenBoardToolbar({
    super.key,
    required this.activeCount,
    required this.updatedAt,
    required this.onRefresh,
    this.onAvailability,
    this.isRefreshing = false,
    this.isReadOnly = false,
  });

  final int activeCount;
  final DateTime? updatedAt;
  final VoidCallback onRefresh;
  final VoidCallback? onAvailability;
  final bool isRefreshing;
  final bool isReadOnly;

  @override
  State<KitchenBoardToolbar> createState() => _KitchenBoardToolbarState();
}

class _KitchenBoardToolbarState extends State<KitchenBoardToolbar> {
  bool _isRefreshPressed = false;
  bool _isAvailabilityPressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final timeLabel = widget.updatedAt != null
        ? KitchenBoardState.formatTimeOfDay(widget.updatedAt!)
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final showUpdateTime = !isCompact && timeLabel != null;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? KkfcSpace.s8 : KkfcSpace.s20,
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: AnimatedSwitcher(
                        duration: reduceMotion
                            ? Duration.zero
                            : KkfcMotion.durMicro,
                        switchInCurve: KkfcMotion.easeOut,
                        switchOutCurve: KkfcMotion.easeIn,
                        child: RichText(
                          key: ValueKey(
                            'toolbar-meta-${widget.activeCount}-$timeLabel-$showUpdateTime',
                          ),
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
                                text: '${widget.activeCount} active',
                                style: const TextStyle(
                                  fontWeight: KkfcFontWeights.bold,
                                  color: KkfcColors.ink,
                                ),
                              ),
                              if (showUpdateTime)
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
                    ),
                    if (widget.isReadOnly) ...[
                      const SizedBox(width: KkfcSpace.s8),
                      Container(
                        key: const ValueKey('kitchen-board-readonly-badge'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: KkfcSpace.s8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: KkfcColors.canvasSunken,
                          borderRadius: BorderRadius.circular(KkfcRadius.sm),
                          border: Border.all(
                            color: KkfcColors.border,
                            width: KkfcBorderWidth.thin,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.visibility_outlined,
                              size: 14,
                              color: KkfcColors.ink2,
                            ),
                            if (!isCompact) ...[
                              const SizedBox(width: 4),
                              const Text(
                                'Read-only (QC Check only)',
                                style: TextStyle(
                                  fontFamily: KkfcFonts.ibmPlexSans,
                                  fontSize: KkfcTextSizes.textXs,
                                  fontWeight: KkfcFontWeights.medium,
                                  color: KkfcColors.ink2,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: isCompact ? KkfcSpace.s4 : KkfcSpace.s12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Listener(
                    onPointerDown: (_) =>
                        setState(() => _isAvailabilityPressed = true),
                    onPointerUp: (_) {
                      if (_isAvailabilityPressed) {
                        setState(() => _isAvailabilityPressed = false);
                      }
                    },
                    onPointerCancel: (_) {
                      if (_isAvailabilityPressed) {
                        setState(() => _isAvailabilityPressed = false);
                      }
                    },
                    child: AnimatedScale(
                      scale: !reduceMotion && _isAvailabilityPressed
                          ? KkfcMotion.pressScale
                          : 1.0,
                      duration: reduceMotion
                          ? Duration.zero
                          : (_isAvailabilityPressed
                                ? KkfcMotion.durPress
                                : KkfcMotion.durRelease),
                      curve: _isAvailabilityPressed
                          ? KkfcMotion.easeOut
                          : KkfcMotion.easeSpring,
                      child: OutlinedButton.icon(
                        key: const ValueKey(
                          'kitchen-board-availability-button',
                        ),
                        onPressed: widget.onAvailability,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: KkfcColors.surface,
                          foregroundColor: KkfcColors.ink,
                          disabledForegroundColor: KkfcColors.ink3,
                          minimumSize: const Size(0, KkfcTargets.webControl),
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact
                                ? KkfcSpace.s8
                                : KkfcSpace.s16,
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
                        icon: const Icon(
                          Icons.event_available_outlined,
                          size: 18,
                          color: KkfcColors.ink,
                        ),
                        label: const Text(
                          'Availability',
                          style: TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: KkfcTextSizes.textMd,
                            fontWeight: KkfcFontWeights.bold,
                            color: KkfcColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isCompact ? KkfcSpace.s4 : KkfcSpace.s12),
                  Listener(
                    onPointerDown: widget.isRefreshing
                        ? null
                        : (_) => setState(() => _isRefreshPressed = true),
                    onPointerUp: (_) {
                      if (_isRefreshPressed) {
                        setState(() => _isRefreshPressed = false);
                      }
                    },
                    onPointerCancel: (_) {
                      if (_isRefreshPressed) {
                        setState(() => _isRefreshPressed = false);
                      }
                    },
                    child: AnimatedScale(
                      scale: !reduceMotion && _isRefreshPressed
                          ? KkfcMotion.pressScale
                          : 1.0,
                      duration: reduceMotion
                          ? Duration.zero
                          : (_isRefreshPressed
                                ? KkfcMotion.durPress
                                : KkfcMotion.durRelease),
                      curve: _isRefreshPressed
                          ? KkfcMotion.easeOut
                          : KkfcMotion.easeSpring,
                      child: OutlinedButton.icon(
                        key: const ValueKey('kitchen-board-refresh-button'),
                        onPressed:
                            widget.isRefreshing ? null : widget.onRefresh,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: KkfcColors.surface,
                          foregroundColor: KkfcColors.ink,
                          disabledForegroundColor: KkfcColors.ink3,
                          minimumSize: const Size(0, KkfcTargets.webControl),
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact
                                ? KkfcSpace.s8
                                : KkfcSpace.s16,
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
                        icon: widget.isRefreshing
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
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
