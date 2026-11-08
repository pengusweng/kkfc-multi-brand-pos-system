import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';

import 'button_state.dart';
import 'button_types.dart';

/// Resolved visual style attributes for a KKFC button.
@immutable
class KkfcResolvedButtonStyle {
  const KkfcResolvedButtonStyle({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.height,
    required this.padding,
    required this.borderRadius,
    required this.textStyle,
    required this.iconSize,
    required this.iconColor,
    required this.focusRingColor,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final double borderWidth;
  final double height;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final TextStyle textStyle;
  final double iconSize;
  final Color iconColor;
  final Color focusRingColor;
}

/// Resolves theme tokens and interactive states into concrete visual styles.
abstract final class KkfcButtonStyleResolver {
  static KkfcResolvedButtonStyle resolve({
    required KkfcButtonVariant variant,
    required KkfcButtonIntent intent,
    required KkfcButtonSize size,
    required KkfcBorderStyle borderStyle,
    required KkfcButtonStateContext state,
    bool prominent = true,
    Color? customForeground,
    Color? customBackground,
    BorderRadius? customRadius,
  }) {
    final height = _resolveHeight(size);
    final padding = _resolvePadding(size);
    final radius = customRadius ?? BorderRadius.circular(KkfcRadius.md);
    final iconSize = _resolveIconSize(size);

    Color bg;
    Color fg;
    Color border;
    double borderWidth = (borderStyle == KkfcBorderStyle.none) ? 0.0 : 1.0;
    final focusRingColor = KkfcColors.focus;

    switch (variant) {
      case KkfcButtonVariant.primary:
      case KkfcButtonVariant.split:
        fg = customForeground ?? KkfcColors.onSolid;
        border = Colors.transparent;
        borderWidth = 0.0;

        if (state.isLoading) {
          bg = customBackground ?? KkfcColors.action;
        } else if (state.isDisabled) {
          // Muted copper for disabled primary action
          bg = const Color(0xFFC5A28D);
        } else if (state.isPressed) {
          bg = KkfcColors.actionPressed;
        } else if (state.isHovered) {
          bg = KkfcColors.actionHover;
        } else {
          bg = customBackground ?? KkfcColors.action;
        }

      case KkfcButtonVariant.outlined:
        if (intent == KkfcButtonIntent.danger) {
          if (state.isDisabled) {
            fg = const Color(0x80B3261E);
            border = const Color(0x80EDB3AF);
            bg = Colors.transparent;
          } else if (state.isPressed) {
            fg = KkfcColors.danger;
            border = KkfcColors.danger;
            bg = const Color(0x22EDB3AF);
          } else if (state.isHovered) {
            fg = KkfcColors.danger;
            border = KkfcColors.danger;
            bg = KkfcColors.dangerBg;
          } else {
            fg = customForeground ?? KkfcColors.danger;
            border = KkfcColors.dangerBorder;
            bg = customBackground ?? Colors.transparent;
          }
        } else {
          // Action / Neutral outlined
          if (state.isDisabled) {
            fg = KkfcColors.ink3;
            border = KkfcColors.border;
            bg = Colors.transparent;
          } else if (state.isPressed) {
            fg = customForeground ?? KkfcColors.ink;
            border = prominent ? KkfcColors.ink : KkfcColors.borderStrong;
            bg = const Color(0x1419293E);
          } else if (state.isHovered) {
            fg = customForeground ?? KkfcColors.ink;
            border = prominent ? KkfcColors.ink : KkfcColors.borderStrong;
            bg = const Color(0x0A19293E);
          } else {
            fg = customForeground ?? KkfcColors.ink;
            border = prominent ? KkfcColors.ink : KkfcColors.border;
            bg = customBackground ?? Colors.transparent;
          }
        }

      case KkfcButtonVariant.subtle:
        border = Colors.transparent;
        borderWidth = 0.0;
        if (state.isDisabled) {
          fg = KkfcColors.ink3;
          bg = KkfcColors.surfaceSubtle;
        } else if (state.isPressed) {
          fg = customForeground ?? KkfcColors.ink;
          bg = const Color(0xFFDCD5C8);
        } else if (state.isHovered) {
          fg = customForeground ?? KkfcColors.ink;
          bg = const Color(0xFFE5DFD4);
        } else {
          fg = customForeground ?? KkfcColors.ink;
          bg = customBackground ?? KkfcColors.canvasSunken;
        }

      case KkfcButtonVariant.ghost:
        border = Colors.transparent;
        borderWidth = 0.0;
        if (intent == KkfcButtonIntent.danger) {
          fg = state.isDisabled ? const Color(0x80B3261E) : KkfcColors.danger;
        } else {
          fg =
              customForeground ??
              (state.isDisabled ? KkfcColors.ink3 : KkfcColors.ink);
        }

        if (state.isDisabled) {
          bg = Colors.transparent;
        } else if (state.isPressed) {
          bg = const Color(0x1419293E);
        } else if (state.isHovered) {
          bg = const Color(0x0A19293E);
        } else {
          bg = customBackground ?? Colors.transparent;
        }
    }

    final textStyle = _resolveTextStyle(size, fg, variant);

    return KkfcResolvedButtonStyle(
      backgroundColor: bg,
      foregroundColor: fg,
      borderColor: border,
      borderWidth: borderWidth,
      height: height,
      padding: padding,
      borderRadius: radius,
      textStyle: textStyle,
      iconSize: iconSize,
      iconColor: fg,
      focusRingColor: focusRingColor,
    );
  }

  static double _resolveHeight(KkfcButtonSize size) {
    switch (size) {
      case KkfcButtonSize.primary:
        return KkfcTargets.posPrimary; // 56.0
      case KkfcButtonSize.standard:
        return KkfcTargets.posMinimum; // 48.0
      case KkfcButtonSize.compact:
        return KkfcTargets.webControl; // 40.0
      case KkfcButtonSize.small:
        return 32.0;
    }
  }

  static EdgeInsetsGeometry _resolvePadding(KkfcButtonSize size) {
    switch (size) {
      case KkfcButtonSize.primary:
        return const EdgeInsets.symmetric(horizontal: KkfcSpace.space5);
      case KkfcButtonSize.standard:
        return const EdgeInsets.symmetric(horizontal: KkfcSpace.space4);
      case KkfcButtonSize.compact:
        return const EdgeInsets.symmetric(horizontal: KkfcSpace.space3);
      case KkfcButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: KkfcSpace.space2);
    }
  }

  static double _resolveIconSize(KkfcButtonSize size) {
    switch (size) {
      case KkfcButtonSize.primary:
        return 20.0;
      case KkfcButtonSize.standard:
        return 20.0;
      case KkfcButtonSize.compact:
        return 18.0;
      case KkfcButtonSize.small:
        return 16.0;
    }
  }

  static TextStyle _resolveTextStyle(
    KkfcButtonSize size,
    Color foregroundColor,
    KkfcButtonVariant variant,
  ) {
    final weight = (variant == KkfcButtonVariant.primary)
        ? KkfcFontWeights.semiBold
        : KkfcFontWeights.medium;

    switch (size) {
      case KkfcButtonSize.primary:
      case KkfcButtonSize.standard:
        return KkfcTypography.textBase.copyWith(
          color: foregroundColor,
          fontWeight: weight,
        );
      case KkfcButtonSize.compact:
        return KkfcTypography.textMd.copyWith(
          color: foregroundColor,
          fontWeight: weight,
        );
      case KkfcButtonSize.small:
        return KkfcTypography.textSm.copyWith(
          color: foregroundColor,
          fontWeight: weight,
        );
    }
  }
}
