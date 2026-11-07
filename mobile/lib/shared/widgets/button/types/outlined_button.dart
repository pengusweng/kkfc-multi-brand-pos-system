import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import '../button_state.dart';
import '../button_style.dart';
import '../button_types.dart';
import '../states/button_interactive.dart';
import '../states/button_loading_state.dart';

/// Outlined button with 1px border on transparent / surface background.
/// Supports standard ink, danger, dashed border (+ Add ingredient), and badge counters.
class KkfcOutlinedButton extends StatelessWidget {
  const KkfcOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.intent = KkfcButtonIntent.action,
    this.borderStyle = KkfcBorderStyle.solid,
    this.prominent = true,
    this.leadingIcon,
    this.trailingIcon,
    this.trailingText,
    this.badge,
    this.size = KkfcButtonSize.standard,
    this.isLoading = false,
    this.loadingLabel,
    this.fullWidth = false,
    this.customBackground,
    this.customForeground,
    this.customRadius,
    this.focusNode,
  });

  final String label;
  final VoidCallback? onPressed;
  final KkfcButtonIntent intent;
  final KkfcBorderStyle borderStyle;
  final bool prominent;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final String? trailingText;
  final Widget? badge;
  final KkfcButtonSize size;
  final bool isLoading;
  final String? loadingLabel;
  final bool fullWidth;
  final Color? customBackground;
  final Color? customForeground;
  final BorderRadius? customRadius;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final isInteractive = onPressed != null && !isLoading;
    final style = KkfcButtonStyleResolver.resolve(
      variant: KkfcButtonVariant.outlined,
      intent: intent,
      size: size,
      borderStyle: borderStyle,
      state: KkfcButtonStateContext(
        isDisabled: onPressed == null,
        isLoading: isLoading,
      ),
      prominent: prominent,
      customBackground: customBackground,
      customForeground: customForeground,
      customRadius: customRadius,
    );

    final isDashed = borderStyle == KkfcBorderStyle.dashed;

    Widget button = OutlinedButton(
      onPressed: isInteractive ? onPressed : null,
      focusNode: focusNode,
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(
          Size(fullWidth ? double.infinity : 0, style.height),
        ),
        padding: WidgetStatePropertyAll(style.padding),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: style.borderRadius),
        ),
        side: isDashed
            ? const WidgetStatePropertyAll(BorderSide.none)
            : WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.focused)) {
                  return BorderSide(
                    color: style.focusRingColor,
                    width: KkfcBorderWidth.focus,
                  );
                }
                if (states.contains(WidgetState.disabled)) {
                  return BorderSide(
                    color: intent == KkfcButtonIntent.danger
                        ? const Color(0x80EDB3AF)
                        : KkfcColors.border,
                    width: style.borderWidth,
                  );
                }
                return BorderSide(
                  color: style.borderColor,
                  width: style.borderWidth,
                );
              }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return Colors.transparent;
          }
          if (states.contains(WidgetState.pressed)) {
            return intent == KkfcButtonIntent.danger
                ? const Color(0x22EDB3AF)
                : const Color(0x1419293E);
          }
          if (states.contains(WidgetState.hovered)) {
            return intent == KkfcButtonIntent.danger
                ? KkfcColors.dangerBg
                : const Color(0x0A19293E);
          }
          return customBackground ?? Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return intent == KkfcButtonIntent.danger
                ? const Color(0x80B3261E)
                : KkfcColors.ink3;
          }
          return style.foregroundColor;
        }),
        elevation: const WidgetStatePropertyAll(0),
      ),
      child: KkfcButtonLoadingState(
        isLoading: isLoading,
        idleContent: _buildIdleContent(style),
        loadingLabel: loadingLabel,
        foregroundColor: style.foregroundColor,
        iconSize: style.iconSize,
        textStyle: style.textStyle,
      ),
    );

    if (isDashed) {
      button = CustomPaint(
        painter: _DashedBorderPainter(
          color: style.borderColor,
          strokeWidth: style.borderWidth,
          borderRadius: style.borderRadius,
        ),
        child: button,
      );
    }

    if (fullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return KkfcPressScaleWrapper(
      enabled: isInteractive,
      child: button,
    );
  }

  Widget _buildIdleContent(KkfcResolvedButtonStyle style) {
    final children = <Widget>[];

    if (leadingIcon != null) {
      children.add(
        IconTheme(
          data: IconThemeData(
            size: style.iconSize,
            color: style.iconColor,
          ),
          child: leadingIcon!,
        ),
      );
      children.add(const SizedBox(width: KkfcSpace.space2));
    }

    children.add(
      Flexible(
        child: Text(
          label,
          style: style.textStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    if (badge != null) {
      children.add(const SizedBox(width: KkfcSpace.space2));
      children.add(badge!);
    }

    if (trailingText != null && trailingText!.isNotEmpty) {
      children.add(const SizedBox(width: KkfcSpace.space3));
      children.add(
        Text(
          trailingText!,
          style: KkfcTypography.withTabular(style.textStyle),
          maxLines: 1,
        ),
      );
    }

    if (trailingIcon != null) {
      children.add(const SizedBox(width: KkfcSpace.space2));
      children.add(
        IconTheme(
          data: IconThemeData(
            size: style.iconSize,
            color: style.iconColor,
          ),
          child: trailingIcon!,
        ),
      );
    }

    return Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }
}

/// Draws a dashed border along a rounded rectangle perimeter.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
  });

  static const double dashLength = 4.0;
  static const double gapLength = 3.0;

  final Color color;
  final double strokeWidth;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (color == Colors.transparent || strokeWidth <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = borderRadius.toRRect(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
    );

    final path = Path()..addRRect(rrect);
    final dashedPath = Path();

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final length = draw ? dashLength : gapLength;
        if (draw) {
          dashedPath.addPath(
            metric.extractPath(distance, distance + length),
            Offset.zero,
          );
        }
        distance += length;
        draw = !draw;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      borderRadius != oldDelegate.borderRadius;
}
