import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';

/// Loading skeleton that mirrors the exact layout, dimensions, borders, and
/// visual rhythm of [AvailabilityItemCard].
class AvailabilityListSkeleton extends StatefulWidget {
  const AvailabilityListSkeleton({
    super.key,
    this.itemCount = 5,
  });

  final int itemCount;

  @override
  State<AvailabilityListSkeleton> createState() =>
      _AvailabilityListSkeletonState();
}

class _AvailabilityListSkeletonState extends State<AvailabilityListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final Animation<double> _shimmer = Tween<double>(
    begin: 0.35,
    end: 0.90,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _controller.stop();
      _controller.value = 0.6;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading availability',
      child: AnimatedBuilder(
        animation: _shimmer,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < widget.itemCount; i++)
                _SkeletonAvailabilityCard(
                  index: i,
                  shimmerValue: _shimmer.value,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SkeletonAvailabilityCard extends StatelessWidget {
  const _SkeletonAvailabilityCard({
    required this.index,
    required this.shimmerValue,
  });

  final int index;
  final double shimmerValue;

  @override
  Widget build(BuildContext context) {
    // Realistic organic variation in text placeholder lengths across cards
    final titleWidths = [180.0, 220.0, 160.0, 200.0, 170.0];
    final subtitleWidths = [130.0, 150.0, 120.0, 140.0, 135.0];

    final titleWidth = titleWidths[index % titleWidths.length];
    final subtitleWidth = subtitleWidths[index % subtitleWidths.length];

    final shimmerBarColor = Color.lerp(
      KkfcColors.canvasSunken,
      KkfcColors.border,
      shimmerValue,
    )!;

    final subtleShimmer = Color.lerp(
      KkfcColors.surfaceSubtle,
      KkfcColors.canvasSunken,
      shimmerValue,
    )!;

    return Container(
      margin: const EdgeInsets.only(bottom: KkfcSpace.s12),
      padding: const EdgeInsets.all(KkfcSpace.s16),
      decoration: BoxDecoration(
        color: KkfcColors.surface,
        borderRadius: BorderRadius.circular(KkfcRadius.md),
        border: Border.all(
          color: KkfcColors.border,
          width: KkfcBorderWidth.thin,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title placeholder
                Container(
                  height: 16.0,
                  width: titleWidth,
                  decoration: BoxDecoration(
                    color: shimmerBarColor,
                    borderRadius: BorderRadius.circular(KkfcRadius.sm / 2),
                  ),
                ),
                const SizedBox(height: KkfcSpace.s8),

                // Category · Brand placeholder
                Container(
                  height: 13.0,
                  width: subtitleWidth,
                  decoration: BoxDecoration(
                    color: subtleShimmer,
                    borderRadius: BorderRadius.circular(KkfcRadius.sm / 2),
                  ),
                ),
                const SizedBox(height: KkfcSpace.s8),

                // Availability status placeholder
                Container(
                  height: 14.0,
                  width: 76.0,
                  decoration: BoxDecoration(
                    color: shimmerBarColor,
                    borderRadius: BorderRadius.circular(KkfcRadius.sm / 2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: KkfcSpace.s12),

          // Change button placeholder
          Container(
            width: 86.0,
            height: 38.0,
            decoration: BoxDecoration(
              color: subtleShimmer,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: KkfcColors.border,
                width: KkfcBorderWidth.thin,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
