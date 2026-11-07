import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import '../button_state.dart';
import '../button_style.dart';
import '../button_types.dart';
import '../states/button_interactive.dart';

/// Square or rounded icon-only button (e.g. "✕", "🔄").
/// Adheres to touch target tokens with centered icon alignment.
class KkfcIconButton extends StatelessWidget {
  const KkfcIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.variant = KkfcButtonVariant.outlined,
    this.intent = KkfcButtonIntent.action,
    this.size = KkfcButtonSize.compact,
    this.borderStyle = KkfcBorderStyle.solid,
    this.prominent = true,
    this.isLoading = false,
    this.customBackground,
    this.customForeground,
    this.customRadius,
    this.tooltip,
    this.focusNode,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final KkfcButtonVariant variant;
  final KkfcButtonIntent intent;
  final KkfcButtonSize size;
  final KkfcBorderStyle borderStyle;
  final bool prominent;
  final bool isLoading;
  final Color? customBackground;
  final Color? customForeground;
  final BorderRadius? customRadius;
  final String? tooltip;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final isInteractive = onPressed != null && !isLoading;
    final style = KkfcButtonStyleResolver.resolve(
      variant: variant,
      intent: intent,
      size: size,
      borderStyle: (variant == KkfcButtonVariant.outlined)
          ? borderStyle
          : KkfcBorderStyle.none,
      state: KkfcButtonStateContext(
        isDisabled: onPressed == null,
        isLoading: isLoading,
      ),
      prominent: prominent,
      customBackground: customBackground,
      customForeground: customForeground,
      customRadius: customRadius,
    );

    final dimension = style.height;

    final child = isLoading
        ? SizedBox(
            width: style.iconSize,
            height: style.iconSize,
            child: CircularProgressIndicator(
              strokeWidth: KkfcBorderWidth.thick,
              valueColor: AlwaysStoppedAnimation<Color>(style.foregroundColor),
            ),
          )
        : IconTheme(
            data: IconThemeData(
              size: style.iconSize,
              color: style.iconColor,
            ),
            child: icon,
          );

    final isOutlined = variant == KkfcButtonVariant.outlined;

    Widget button;

    if (isOutlined) {
      button = OutlinedButton(
        onPressed: isInteractive ? onPressed : null,
        focusNode: focusNode,
        style: ButtonStyle(
          fixedSize: WidgetStatePropertyAll(Size(dimension, dimension)),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: style.borderRadius),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return BorderSide(
                color: style.focusRingColor,
                width: KkfcBorderWidth.focus,
              );
            }
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(
                color: KkfcColors.border,
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
              return const Color(0x1419293E);
            }
            if (states.contains(WidgetState.hovered)) {
              return const Color(0x0A19293E);
            }
            return customBackground ?? Colors.transparent;
          }),
          foregroundColor: WidgetStatePropertyAll(style.foregroundColor),
          elevation: const WidgetStatePropertyAll(0),
        ),
        child: child,
      );
    } else {
      button = FilledButton(
        onPressed: isInteractive ? onPressed : null,
        focusNode: focusNode,
        style: ButtonStyle(
          fixedSize: WidgetStatePropertyAll(Size(dimension, dimension)),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: style.borderRadius),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (isLoading) {
              return customBackground ?? KkfcColors.action;
            }
            if (states.contains(WidgetState.disabled)) {
              return const Color(0xFFC5A28D);
            }
            if (states.contains(WidgetState.pressed)) {
              return KkfcColors.actionPressed;
            }
            if (states.contains(WidgetState.hovered)) {
              return KkfcColors.actionHover;
            }
            return customBackground ?? KkfcColors.action;
          }),
          foregroundColor: WidgetStatePropertyAll(style.foregroundColor),
          elevation: const WidgetStatePropertyAll(0),
        ),
        child: child,
      );
    }

    button = KkfcPressScaleWrapper(
      enabled: isInteractive,
      child: button,
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
