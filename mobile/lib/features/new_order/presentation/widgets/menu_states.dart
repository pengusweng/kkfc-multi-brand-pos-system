import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/shared/shared_layout.dart';
import 'package:mobile/shared/widgets/responsive_card_grid.dart';

class MenuGridSkeleton extends StatefulWidget {
  const MenuGridSkeleton({super.key});

  @override
  State<MenuGridSkeleton> createState() => _MenuGridSkeletonState();
}

class _MenuGridSkeletonState extends State<MenuGridSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final Animation<double> _opacity = Tween<double>(
    begin: 0.45,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _controller.stop();
      _controller.value = 1;
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
    final scheme = Theme.of(context).colorScheme;
    Widget bar(double h, {double? w}) => Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(MenuRadius.sm),
      ),
    );

    return Semantics(
      label: 'Loading menu',
      child: FadeTransition(
        opacity: _opacity,
        child: ResponsiveCardGrid(
          itemCount: 8,
          itemBuilder: (context, _) => DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(MenuRadius.md),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(MenuSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: bar(double.infinity),
                  ),
                  const SizedBox(height: MenuSpace.md),
                  bar(14, w: 90),
                  const SizedBox(height: MenuSpace.sm),
                  bar(10),
                  const SizedBox(height: MenuSpace.md),
                  bar(14, w: 60),
                ],
              ),
            ),
          ),
        ),
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
                    child: Icon(
                      icon,
                      size: 28,
                      color: const Color(0xFFB42318),
                    ),
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
