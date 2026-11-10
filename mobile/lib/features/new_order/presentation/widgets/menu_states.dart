import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/shared/shared_layout.dart';

/// Loading skeleton that mirrors the exact layout, dimensions, borders, and
/// visual rhythm of [MenuItemCard] across both wide tablet/desktop and phone layouts.
class MenuGridSkeleton extends StatefulWidget {
  const MenuGridSkeleton({super.key, this.isWide});

  final bool? isWide;

  @override
  State<MenuGridSkeleton> createState() => _MenuGridSkeletonState();
}

class _MenuGridSkeletonState extends State<MenuGridSkeleton>
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
    if (context.reduceMotion) {
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
    final isWide = widget.isWide ?? (MediaQuery.sizeOf(context).width >= 850.0);

    return Semantics(
      label: 'Loading menu',
      child: AnimatedBuilder(
        animation: _shimmer,
        builder: (context, _) {
          return isWide
              ? GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    mainAxisExtent: 140.0,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) => _SkeletonCard(
                    index: index,
                    shimmerValue: _shimmer.value,
                    compact: false,
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12.0),
                  itemBuilder: (context, index) => _SkeletonCard(
                    index: index,
                    shimmerValue: _shimmer.value,
                    compact: true,
                  ),
                );
        },
      ),
    );
  }
}

/// A skeleton placeholder item matching [MenuItemCard]'s structure.
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({
    required this.index,
    required this.shimmerValue,
    required this.compact,
  });

  final int index;
  final double shimmerValue;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // Vary title and description widths slightly across cards for organic realism
    final titleWidths = [150.0, 180.0, 130.0, 165.0, 140.0, 175.0];
    final titleWidth = titleWidths[index % titleWidths.length];

    final descWidths = [0.85, 0.70, 0.90, 0.60, 0.75, 0.80];
    final descWidthFactor = descWidths[index % descWidths.length];

    final shimmerColor = Color.lerp(
      const Color(0xFFEEE8DC),
      const Color(0xFFDDD6C9),
      shimmerValue,
    )!;

    final subtleShimmer = Color.lerp(
      const Color(0xFFF7F3EC),
      const Color(0xFFEBE5DA),
      shimmerValue,
    )!;

    Widget bar(double h, {double? w, double radius = 4.0}) => Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: shimmerColor,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    return Container(
      height: compact ? null : 140.0,
      padding: const EdgeInsets.all(16.0),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top section: Title and Description placeholders
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              bar(18.0, w: titleWidth, radius: 4.0),
              const SizedBox(height: 8.0),
              FractionallySizedBox(
                widthFactor: descWidthFactor,
                child: bar(12.0, radius: 4.0),
              ),
              if (!compact) ...[
                const SizedBox(height: 5.0),
                FractionallySizedBox(
                  widthFactor: (descWidthFactor * 0.65).clamp(0.3, 0.55),
                  child: bar(12.0, radius: 4.0),
                ),
              ],
            ],
          ),

          if (compact) const SizedBox(height: 16.0),

          // Bottom section: Price and Add button placeholders
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              bar(20.0, w: 68.0, radius: 4.0),
              Container(
                height: 32.0,
                width: 74.0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: subtleShimmer,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: const Color(0xFFDDD6C9),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 14.0,
                      height: 14.0,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(3.0),
                      ),
                    ),
                    const SizedBox(width: 6),
                    bar(10.0, w: 26.0, radius: 3.0),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MenuMessageCard extends StatelessWidget {
  const MenuMessageCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 28.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFFDDD6C9), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3F2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFECDCA),
                      width: 1.0,
                    ),
                  ),
                  child: Center(
                    child: Icon(icon, size: 28, color: const Color(0xFFB42318)),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: KkfcFonts.ibmPlexSans,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF19293E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: KkfcFonts.text,
                    fontSize: 14.0,
                    color: Color(0xFF586579),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: Material(
                    color: const Color(0xFFA8562A),
                    borderRadius: BorderRadius.circular(10.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10.0),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        onAction();
                      },
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.refresh,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              actionLabel,
                              style: const TextStyle(
                                fontFamily: KkfcFonts.ibmPlexSans,
                                fontSize: 15.0,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
