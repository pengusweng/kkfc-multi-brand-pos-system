import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/shared/widgets/wave_accents.dart';

/// Top navy header displaying the KKFC logo, Multi-brand POS title,
/// and brand labels situated in the middle with decorative wave arcs.
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
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildBranding(context),
                      const SizedBox(height: KkfcSpace.space2),
                      Center(child: _buildBrands(context)),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _buildBranding(context),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(child: _buildBrands(context)),
                      ),
                      const Expanded(flex: 1, child: SizedBox.shrink()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranding(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: KkfcSpace.space3,
      runSpacing: KkfcSpace.space1,
      children: [
        Image.asset(
          'assets/images/logo_light.png',
          key: const ValueKey('brand-panel-logo'),
          height: compact ? 22.0 : 26.0,
          fit: BoxFit.contain,
          semanticLabel: 'KKFC',
          errorBuilder: (context, error, stackTrace) => Text(
            'KKFC',
            style: (compact ? KkfcTypography.text2xl : KkfcTypography.text3xl)
                .copyWith(
                  color: Colors.white,
                  fontWeight: KkfcFontWeights.bold,
                  letterSpacing: 1.5,
                ),
          ),
        ),
        Text(
          'Multi-brand POS',
          key: const ValueKey('brand-panel-title'),
          style: (compact ? KkfcTypography.textMd : KkfcTypography.textBase)
              .copyWith(
                color: Colors.white.withValues(alpha: 0.95),
                fontWeight: KkfcFontWeights.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildBrands(BuildContext context) {
    final brandStyle = KkfcTypography.textXs.copyWith(
      color: Colors.white.withValues(alpha: 0.65),
      fontWeight: KkfcFontWeights.regular,
    );

    return KeyedSubtree(
      key: const ValueKey('brand-panel-brands'),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: compact ? KkfcSpace.space2 : KkfcSpace.space3,
        runSpacing: 2,
        children: [
          Text('Gamcheon', style: brandStyle),
          Text('·', style: brandStyle),
          Text("Aurelia's Inasal", style: brandStyle),
          Text('·', style: brandStyle),
          Text('King Kungs Kafé', style: brandStyle),
        ],
      ),
    );
  }
}

/// Backward compatibility alias for [HeaderWavesPainter].
typedef _HeaderWavesPainter = HeaderWavesPainter;
