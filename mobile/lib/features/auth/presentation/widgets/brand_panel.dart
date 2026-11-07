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
            child: CustomPaint(
              painter: _HeaderWavesPainter(),
            ),
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
    final paint = Paint()
      ..color = const Color(0x35A8562A) // Soft copper tint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path1 = Path();
    path1.moveTo(size.width * 0.45, 0);
    path1.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.7,
      size.width,
      size.height * 0.35,
    );
    canvas.drawPath(path1, paint);

    final path2 = Path();
    path2.moveTo(size.width * 0.58, 0);
    path2.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.85,
      size.width,
      size.height * 0.55,
    );
    canvas.drawPath(path2, paint);

    final path3 = Path();
    path3.moveTo(size.width * 0.72, 0);
    path3.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.95,
      size.width,
      size.height * 0.8,
    );
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
