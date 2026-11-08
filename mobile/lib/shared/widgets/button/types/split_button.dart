import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';

import '../button_state.dart';
import '../button_style.dart';
import '../button_types.dart';
import '../states/button_interactive.dart';
import '../states/button_loading_state.dart';

/// Dual-aligned button with left-aligned label/icon and right-aligned value/action/chevron.
/// Essential for POS order bars, cart summaries, and action panels.
class KkfcSplitButton extends StatelessWidget {
  const KkfcSplitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingValue,
    this.leadingIcon,
    this.trailingIcon,
    this.variant = KkfcButtonVariant.primary,
    this.intent = KkfcButtonIntent.action,
    this.size = KkfcButtonSize.primary,
    this.isLoading = false,
    this.loadingLabel,
    this.fullWidth = true,
    this.customBackground,
    this.customForeground,
    this.customRadius,
    this.focusNode,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? trailingValue;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final KkfcButtonVariant variant;
  final KkfcButtonIntent intent;
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
    final isOutlined = variant == KkfcButtonVariant.outlined;

    final style = KkfcButtonStyleResolver.resolve(
      variant: variant,
      intent: intent,
      size: size,
      borderStyle: isOutlined ? KkfcBorderStyle.solid : KkfcBorderStyle.none,
      state: KkfcButtonStateContext(
        isDisabled: onPressed == null,
        isLoading: isLoading,
      ),
      prominent: true,
      customBackground: customBackground,
      customForeground: customForeground,
      customRadius: customRadius,
    );

    final buttonStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(fullWidth ? double.infinity : 0, style.height),
      ),
      padding: WidgetStatePropertyAll(style.padding),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: style.borderRadius),
      ),
      side: isOutlined
          ? WidgetStateProperty.resolveWith((states) {
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
            })
          : const WidgetStatePropertyAll(BorderSide.none),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (isOutlined) {
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
        }

        // Primary solid split button
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
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (isOutlined && states.contains(WidgetState.disabled)) {
          return KkfcColors.ink3;
        }
        return style.foregroundColor;
      }),
      elevation: const WidgetStatePropertyAll(0),
    );

    Widget button = isOutlined
        ? OutlinedButton(
            onPressed: isInteractive ? onPressed : null,
            focusNode: focusNode,
            style: buttonStyle,
            child: KkfcButtonLoadingState(
              isLoading: isLoading,
              idleContent: _buildIdleContent(style),
              loadingLabel: loadingLabel,
              foregroundColor: style.foregroundColor,
              iconSize: style.iconSize,
              textStyle: style.textStyle,
            ),
          )
        : FilledButton(
            onPressed: isInteractive ? onPressed : null,
            focusNode: focusNode,
            style: buttonStyle,
            child: KkfcButtonLoadingState(
              isLoading: isLoading,
              idleContent: _buildIdleContent(style),
              loadingLabel: loadingLabel,
              foregroundColor: style.foregroundColor,
              iconSize: style.iconSize,
              textStyle: style.textStyle,
            ),
          );

    if (fullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return KkfcPressScaleWrapper(enabled: isInteractive, child: button);
  }

  Widget _buildIdleContent(KkfcResolvedButtonStyle style) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left section: leading icon + label
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                IconTheme(
                  data: IconThemeData(
                    size: style.iconSize,
                    color: style.iconColor,
                  ),
                  child: leadingIcon!,
                ),
                const SizedBox(width: KkfcSpace.space2),
              ],
              Flexible(
                child: Text(
                  label,
                  style: style.textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Right section: trailing value + trailing icon
        if ((trailingValue != null && trailingValue!.isNotEmpty) ||
            trailingIcon != null) ...[
          const SizedBox(width: KkfcSpace.space3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailingValue != null && trailingValue!.isNotEmpty)
                Text(
                  trailingValue!,
                  style: KkfcTypography.withTabular(style.textStyle),
                  maxLines: 1,
                ),
              if (trailingIcon != null) ...[
                if (trailingValue != null && trailingValue!.isNotEmpty)
                  const SizedBox(width: KkfcSpace.space2),
                IconTheme(
                  data: IconThemeData(
                    size: style.iconSize,
                    color: style.iconColor,
                  ),
                  child: trailingIcon!,
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
