import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';

/// Top navy header displaying the KKFC brand, Staff POS title,
/// and brand labels with decorative wave arcs.
class BrandPanel extends StatelessWidget {
  const BrandPanel({super.key, required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: KkfcColors.shell, // Navy #19293E
      child: Stack(
        children: [
          const Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 260,
            child: CustomPaint(painter: _HeaderWavesPainter()),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? KkfcSpace.space4 : KkfcSpace.space6,
              vertical: compact ? KkfcSpace.space3 : KkfcSpace.space4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'KKFC',
                  style: KkfcTypography.textLg.copyWith(
                    color: Colors.white,
                    fontWeight: KkfcFontWeights.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Staff POS',
                  style: KkfcTypography.textSm.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: KkfcFontWeights.regular,
                  ),
                ),
                const SizedBox(height: 6),
                _buildBrands(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrands(BuildContext context) {
    final brandStyle = KkfcTypography.textXs.copyWith(
      color: Colors.white.withValues(alpha: 0.65),
      fontWeight: KkfcFontWeights.regular,
    );

    if (compact) {
      return Wrap(
        spacing: KkfcSpace.space2,
        runSpacing: 2,
        children: [
          Text('Gamcheon', style: brandStyle),
          Text('·', style: brandStyle),
          Text("Aurelia's Inasal", style: brandStyle),
          Text('·', style: brandStyle),
          Text('King Kungs Kafé', style: brandStyle),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Gamcheon', style: brandStyle),
        const SizedBox(width: KkfcSpace.space4),
        Text("Aurelia's Inasal", style: brandStyle),
        const SizedBox(width: KkfcSpace.space4),
        Text('King Kungs Kafé', style: brandStyle),
      ],
    );
  }
}

/// Draws subtle decorative copper wave/arc lines in the top right of the header.
class _HeaderWavesPainter extends CustomPainter {
  const _HeaderWavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final w = size.width;
    final h = size.height;

    // Ambient subtle copper corner glow on the navy shell
    final glowPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment.topRight,
        radius: 0.9,
        colors: [
          Color(0x18B86843),
          Color(0x0019293E),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, glowPaint);

    final strokeShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomLeft,
      colors: [
        Color(0x55B86843), // Rich warm copper
        Color(0x35A8562A), // Terracotta
        Color(0x10FF9248), // Warm amber fade
      ],
    ).createShader(rect);

    // Arc 1: Innermost subtle ripple
    final path1 = Path()
      ..moveTo(w * 0.35, 0)
      ..cubicTo(
        w * 0.58, h * 0.35,
        w * 0.78, h * 0.65,
        w, h * 0.40,
      );
    final paint1 = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round
      ..shader = strokeShader;
    canvas.drawPath(path1, paint1);

    // Arc 2: Primary harmonic arc
    final path2 = Path()
      ..moveTo(w * 0.48, 0)
      ..cubicTo(
        w * 0.68, h * 0.48,
        w * 0.85, h * 0.82,
        w, h * 0.58,
      );
    final paint2 = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..shader = strokeShader;
    canvas.drawPath(path2, paint2);

    // Arc 3: Secondary outer arc
    final path3 = Path()
      ..moveTo(w * 0.62, 0)
      ..cubicTo(
        w * 0.78, h * 0.58,
        w * 0.90, h * 0.92,
        w, h * 0.74,
      );
    final paint3 = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..shader = strokeShader;
    canvas.drawPath(path3, paint3);

    // Arc 4: Outer fine echo arc
    final path4 = Path()
      ..moveTo(w * 0.76, 0)
      ..cubicTo(
        w * 0.86, h * 0.68,
        w * 0.94, h * 0.98,
        w, h * 0.88,
      );
    final paint4 = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x25A8562A);
    canvas.drawPath(path4, paint4);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
