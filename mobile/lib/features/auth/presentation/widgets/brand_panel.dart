import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/shared/widgets/wave_accents.dart';

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
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: KkfcSpace.space3,
                  runSpacing: KkfcSpace.space1,
                  children: [
                    Text(
                      'KKFC',
                      style:
                          (compact
                                  ? KkfcTypography.text2xl
                                  : KkfcTypography.text3xl)
                              .copyWith(
                                color: Colors.white,
                                fontWeight: KkfcFontWeights.bold,
                                letterSpacing: 1.5,
                              ),
                    ),
                    Text(
                      'Staff POS',
                      style:
                          (compact
                                  ? KkfcTypography.textBase
                                  : KkfcTypography.textLg)
                              .copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: KkfcFontWeights.regular,
                              ),
                    ),
                  ],
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

/// Backward compatibility alias for [HeaderWavesPainter].
typedef _HeaderWavesPainter = HeaderWavesPainter;
