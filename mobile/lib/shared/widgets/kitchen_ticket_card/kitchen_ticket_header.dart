import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/shared/data/models/kitchen_ticket_data.dart';

class KitchenTicketHeader extends StatelessWidget {
  const KitchenTicketHeader({
    super.key,
    required this.ticketNumber,
    required this.elapsed,
    required this.age,
  });

  final String ticketNumber;
  final Duration elapsed;
  final KitchenTicketAge age;

  static String formatElapsed(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final time = formatElapsed(elapsed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                ticketNumber,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: KkfcColors.ticketInk,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              time,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: KkfcColors.ticketInk,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        KitchenTicketProgressBar(elapsed: elapsed, age: age),
      ],
    );
  }
}

class KitchenTicketProgressBar extends StatelessWidget {
  const KitchenTicketProgressBar({
    super.key,
    required this.elapsed,
    required this.age,
  });

  final Duration elapsed;
  final KitchenTicketAge age;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 12,
      child: CustomPaint(
        painter: _ProgressBarPainter(elapsed: elapsed, age: age),
      ),
    );
  }
}

class _ProgressBarPainter extends CustomPainter {
  const _ProgressBarPainter({required this.elapsed, required this.age});

  final Duration elapsed;
  final KitchenTicketAge age;

  @override
  void paint(Canvas canvas, Size size) {
    const barHeight = 5.0;
    final barY = (size.height - barHeight) / 2;
    const barRadius = Radius.circular(2.5);

    // Track
    final trackPaint = Paint()
      ..color = KkfcColors.ticketBorder
      ..style = PaintingStyle.fill;
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, barY, size.width, barHeight),
      barRadius,
    );
    canvas.drawRRect(trackRect, trackPaint);

    // Fill
    const maxSeconds = 10 * 60.0;
    final progress = (elapsed.inSeconds / maxSeconds).clamp(0.02, 1.0);
    final fillWidth = size.width * progress;

    final fillColor = switch (age) {
      KitchenTicketAge.onTime => KkfcColors.ticketAgeOnTime,
      KitchenTicketAge.dueSoon => KkfcColors.ticketAgeDueSoon,
      KitchenTicketAge.late => KkfcColors.ticketAgeLate,
    };

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final fillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, barY, fillWidth, barHeight),
      barRadius,
    );
    canvas.drawRRect(fillRect, fillPaint);

    // Tick lines at 50% (5 min) and 75% (8 min)
    final tickPaint = Paint()
      ..color = KkfcColors.ticketSubtleInk
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const tickHeight = 11.0;
    final tickY1 = (size.height - tickHeight) / 2;
    final tickY2 = tickY1 + tickHeight;

    final tick1X = size.width * 0.50;
    canvas.drawLine(Offset(tick1X, tickY1), Offset(tick1X, tickY2), tickPaint);

    final tick2X = size.width * 0.75;
    canvas.drawLine(Offset(tick2X, tickY1), Offset(tick2X, tickY2), tickPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressBarPainter oldDelegate) =>
      oldDelegate.elapsed != elapsed || oldDelegate.age != age;
}
