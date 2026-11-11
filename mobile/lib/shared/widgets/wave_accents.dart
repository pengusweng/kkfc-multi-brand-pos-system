import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';

/// Draws subtle decorative copper wave/arc lines on the navy shell header background.
///
/// Shared across [BrandPanel] on the login screen and [AppHeader] throughout
/// the application to maintain KKFC's signature artisanal brand identity.
class HeaderWavesPainter extends CustomPainter {
  const HeaderWavesPainter();

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
        colors: [Color(0x18B86843), Color(0x0019293E)],
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
      ..cubicTo(w * 0.58, h * 0.35, w * 0.78, h * 0.65, w, h * 0.40);
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
      ..cubicTo(w * 0.68, h * 0.48, w * 0.85, h * 0.82, w, h * 0.58);
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
      ..cubicTo(w * 0.78, h * 0.58, w * 0.90, h * 0.92, w, h * 0.74);
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
      ..cubicTo(w * 0.86, h * 0.68, w * 0.94, h * 0.98, w, h * 0.88);
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

/// Draws soft, elegant organic wave curves and precision contour lines
/// on the warm sand canvas background (#F7F3EC).
///
/// Shared across the login screen and menu screen page to ground catalog
/// items and interactive cards in a warm, artisanal landscape.
class CanvasWavesPainter extends CustomPainter {
  const CanvasWavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final w = size.width;
    final h = size.height;

    // 0. Soft ambient luminous warmth behind the composition
    final glowPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.25, 0.15),
        radius: 0.85,
        colors: [
          Color(0x22F9EBE2), // Subtle copper action-tint glow
          Color(0x00F9EBE2),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, glowPaint);

    // =========================================================================
    // WAVE 1: Broad Base Sand Dune (Expansive rolling groundwave)
    // =========================================================================
    final path1 = Path()
      ..moveTo(0, h * 0.90)
      ..cubicTo(w * 0.18, h * 0.84, w * 0.32, h * 0.88, w * 0.48, h * 0.80)
      ..cubicTo(w * 0.64, h * 0.72, w * 0.78, h * 0.78, w * 0.90, h * 0.68)
      ..cubicTo(w * 0.95, h * 0.63, w * 0.98, h * 0.60, w, h * 0.58)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final fill1 = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0x10DDD6C9), Color(0x3EDDD6C9)],
      ).createShader(rect);
    canvas.drawPath(path1, fill1);

    // =========================================================================
    // WAVE 2: Mid-tier Warm Amber & Sand Wave (Secondary fluid contour)
    // =========================================================================
    final path2 = Path()
      ..moveTo(w * 0.18, h)
      ..cubicTo(w * 0.32, h * 0.88, w * 0.46, h * 0.82, w * 0.60, h * 0.85)
      ..cubicTo(w * 0.74, h * 0.88, w * 0.86, h * 0.74, w, h * 0.68)
      ..lineTo(w, h)
      ..close();

    final fill2 = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topRight,
        colors: [Color(0x14C5A28D), Color(0x3AC5A28D)],
      ).createShader(rect);
    canvas.drawPath(path2, fill2);

    // =========================================================================
    // WAVE 3: Foreground Terracotta Copper Dune (Artisanal brand core)
    // =========================================================================
    final path3 = Path()
      ..moveTo(w * 0.42, h)
      ..cubicTo(w * 0.58, h * 0.91, w * 0.70, h * 0.84, w * 0.82, h * 0.86)
      ..cubicTo(w * 0.91, h * 0.88, w * 0.96, h * 0.80, w, h * 0.78)
      ..lineTo(w, h)
      ..close();

    final fill3 = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topRight,
        colors: [Color(0x18A8562A), Color(0x3CB86843)],
      ).createShader(rect);
    canvas.drawPath(path3, fill3);

    // =========================================================================
    // WAVE 4: Top-Left Organic Aether Curve (Visual counter-balance)
    // =========================================================================
    final path4 = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.36, 0)
      ..cubicTo(w * 0.28, h * 0.14, w * 0.22, h * 0.22, w * 0.12, h * 0.30)
      ..cubicTo(w * 0.06, h * 0.35, w * 0.02, h * 0.40, 0, h * 0.44)
      ..close();

    final fill4 = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x28DDD6C9), Color(0x08DDD6C9)],
      ).createShader(rect);
    canvas.drawPath(path4, fill4);

    // =========================================================================
    // CONTOUR ACCENTS: Hand-crafted Precision Stroke Lines
    // =========================================================================

    // Contour 1: Tracing the ridge of Wave 1
    final strokePath1 = Path()
      ..moveTo(0, h * 0.90)
      ..cubicTo(w * 0.18, h * 0.84, w * 0.32, h * 0.88, w * 0.48, h * 0.80)
      ..cubicTo(w * 0.64, h * 0.72, w * 0.78, h * 0.78, w * 0.90, h * 0.68)
      ..cubicTo(w * 0.95, h * 0.63, w * 0.98, h * 0.60, w, h * 0.58);

    final strokePaint1 = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0x15A8562A), Color(0x45A8562A), Color(0x20C5A28D)],
      ).createShader(rect);
    canvas.drawPath(strokePath1, strokePaint1);

    // Contour 2: Harmonic Echo line floating above Wave 1
    final strokePath2 = Path()
      ..moveTo(0, h * 0.87)
      ..cubicTo(w * 0.18, h * 0.81, w * 0.32, h * 0.85, w * 0.48, h * 0.77)
      ..cubicTo(w * 0.64, h * 0.69, w * 0.78, h * 0.75, w * 0.90, h * 0.65)
      ..cubicTo(w * 0.95, h * 0.60, w * 0.98, h * 0.57, w, h * 0.55);

    final strokePaint2 = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0x05C5A28D), Color(0x30C5A28D), Color(0x05C5A28D)],
      ).createShader(rect);
    canvas.drawPath(strokePath2, strokePaint2);

    // Contour 3: Tracing the ridge of Wave 2
    final strokePath3 = Path()
      ..moveTo(w * 0.18, h)
      ..cubicTo(w * 0.32, h * 0.88, w * 0.46, h * 0.82, w * 0.60, h * 0.85)
      ..cubicTo(w * 0.74, h * 0.88, w * 0.86, h * 0.74, w, h * 0.68);

    final strokePaint3 = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0x10B86843), Color(0x48B86843), Color(0x20A8562A)],
      ).createShader(rect);
    canvas.drawPath(strokePath3, strokePaint3);

    // Contour 4: Tracing the ridge of Wave 3 (Warm copper foreground crest)
    final strokePath4 = Path()
      ..moveTo(w * 0.42, h)
      ..cubicTo(w * 0.58, h * 0.91, w * 0.70, h * 0.84, w * 0.82, h * 0.86)
      ..cubicTo(w * 0.91, h * 0.88, w * 0.96, h * 0.80, w, h * 0.78);

    final strokePaint4 = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topRight,
        colors: [Color(0x20A8562A), Color(0x55A8562A), Color(0x15A8562A)],
      ).createShader(rect);
    canvas.drawPath(strokePath4, strokePaint4);

    // Contour 5: Top-Left Aura contour stroke
    final strokePath5 = Path()
      ..moveTo(w * 0.36, 0)
      ..cubicTo(w * 0.28, h * 0.14, w * 0.22, h * 0.22, w * 0.12, h * 0.30)
      ..cubicTo(w * 0.06, h * 0.35, w * 0.02, h * 0.40, 0, h * 0.44);

    final strokePaint5 = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0x35C5A28D), Color(0x15DDD6C9)],
      ).createShader(rect);
    canvas.drawPath(strokePath5, strokePaint5);

    // Contour 6: Inner Top-Left echo arc
    final strokePath6 = Path()
      ..moveTo(w * 0.26, 0)
      ..cubicTo(w * 0.20, h * 0.10, w * 0.15, h * 0.16, w * 0.08, h * 0.22)
      ..cubicTo(w * 0.04, h * 0.26, w * 0.01, h * 0.29, 0, h * 0.32);

    final strokePaint6 = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x20DDD6C9);
    canvas.drawPath(strokePath6, strokePaint6);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A ready-to-use widget that displays the fluid background waves and contours
/// on top of the warm sand canvas background ([KkfcColors.canvas]).
class KkfcCanvasWaves extends StatelessWidget {
  const KkfcCanvasWaves({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: KkfcColors.canvas),
      child: CustomPaint(
        painter: CanvasWavesPainter(),
      ),
    );
  }
}

/// A ready-to-use widget that displays subtle decorative copper wave/arc lines
/// for the navy shell header ([KkfcColors.shell]).
class KkfcHeaderWaves extends StatelessWidget {
  const KkfcHeaderWaves({
    super.key,
    this.width = 260.0,
  });

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: const CustomPaint(
        painter: HeaderWavesPainter(),
      ),
    );
  }
}
