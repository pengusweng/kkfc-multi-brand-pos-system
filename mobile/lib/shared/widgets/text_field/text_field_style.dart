import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';

import 'states/text_field_state.dart';
import 'text_field_types.dart';

/// Resolved styling attributes for a KKFC text field.
@immutable
class KkfcResolvedTextFieldStyle {
  const KkfcResolvedTextFieldStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
    required this.height,
    required this.contentPadding,
    required this.textStyle,
    required this.hintStyle,
    required this.iconColor,
  });

  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;
  final double? height;
  final EdgeInsetsGeometry contentPadding;
  final TextStyle textStyle;
  final TextStyle hintStyle;
  final Color iconColor;

  /// Generates Flutter OutlineInputBorder matching this resolved style.
  OutlineInputBorder toOutlineInputBorder() {
    if (borderWidth <= 0 || borderColor == Colors.transparent) {
      return OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide.none,
      );
    }
    return OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: borderColor, width: borderWidth),
    );
  }
}

/// Resolves design tokens into concrete styles based on variant, state, size, and shape.
abstract final class KkfcTextFieldStyleResolver {
  static KkfcResolvedTextFieldStyle resolve({
    required KkfcTextFieldVariant variant,
    required KkfcTextFieldStateContext state,
    KkfcTextFieldSize size = KkfcTextFieldSize.standard,
    KkfcTextFieldShape shape = KkfcTextFieldShape.rounded,
    KkfcSelectTheme selectTheme = KkfcSelectTheme.outlined,
    bool isNumeric = false,
    bool isBold = false,
    TextAlign textAlign = TextAlign.start,
    Color? customBackground,
    Color? customForeground,
    BorderRadius? customRadius,
    TextStyle? customTextStyle,
  }) {
    final height = (variant == KkfcTextFieldVariant.multiline)
        ? null
        : _resolveHeight(size);

    final padding = _resolvePadding(size, variant);
    final radius = customRadius ?? _resolveRadius(shape);

    Color bg;
    Color border;
    double borderWidth;
    Color textCol;
    Color hintCol;

    if (selectTheme == KkfcSelectTheme.darkShell) {
      // Dark navy shell selector as shown in row 25
      bg = KkfcColors.shell;
      border = Colors.transparent;
      borderWidth = 0.0;
      textCol = KkfcColors.onSelected;
      hintCol = const Color(0xB3FFFFFF);
    } else if (variant == KkfcTextFieldVariant.sunken ||
        selectTheme == KkfcSelectTheme.subtle) {
      // Warm sand sunken background
      bg = customBackground ?? KkfcColors.canvasSunken;
      border = Colors.transparent;
      borderWidth = 0.0;
      textCol = customForeground ?? KkfcColors.ink;
      hintCol = KkfcColors.ink3;
    } else {
      // Standard outlined field on surface
      bg = customBackground ?? KkfcColors.surface;

      if (shape == KkfcTextFieldShape.borderless) {
        border = Colors.transparent;
        borderWidth = 0.0;
      } else {
        switch (state.currentState) {
          case KkfcTextFieldState.error:
            border = KkfcColors.danger;
            borderWidth = KkfcBorderWidth.thick; // 2.0
          case KkfcTextFieldState.focused:
            border = KkfcColors.focus; // Blue #1F66C9
            borderWidth = KkfcBorderWidth.thick; // 2.0
          case KkfcTextFieldState.disabled:
            border = KkfcColors.border; // #DDD6C9
            borderWidth = KkfcBorderWidth.thin;
            bg = KkfcColors.surfaceSubtle;
          case KkfcTextFieldState.idle:
            border = state.isHovered
                ? KkfcColors.ink2
                : KkfcColors.borderStrong; // #76849A
            borderWidth = KkfcBorderWidth.thin;
        }
      }

      textCol =
          customForeground ??
          (state.isEnabled ? KkfcColors.ink : KkfcColors.ink3);
      hintCol = KkfcColors.ink3;
    }

    var baseStyle = (size == KkfcTextFieldSize.compact)
        ? KkfcTypography.textMd
        : KkfcTypography.textBase;

    if (isBold) {
      baseStyle = baseStyle.copyWith(fontWeight: KkfcFontWeights.bold);
    }

    if (isNumeric) {
      baseStyle = KkfcTypography.withTabular(baseStyle);
    }

    final textStyle = (customTextStyle != null)
        ? customTextStyle.copyWith(color: textCol)
        : baseStyle.copyWith(color: textCol);

    final hintStyle = baseStyle.copyWith(
      color: hintCol,
      fontWeight: KkfcFontWeights.regular,
    );

    return KkfcResolvedTextFieldStyle(
      backgroundColor: bg,
      borderColor: border,
      borderWidth: borderWidth,
      borderRadius: radius,
      height: height,
      contentPadding: padding,
      textStyle: textStyle,
      hintStyle: hintStyle,
      iconColor: textCol,
    );
  }

  static double _resolveHeight(KkfcTextFieldSize size) {
    switch (size) {
      case KkfcTextFieldSize.large:
        return KkfcTargets.posPrimary; // 56.0
      case KkfcTextFieldSize.standard:
        return KkfcTargets.posMinimum; // 48.0
      case KkfcTextFieldSize.compact:
        return KkfcTargets.webControl; // 40.0
    }
  }

  static EdgeInsetsGeometry _resolvePadding(
    KkfcTextFieldSize size,
    KkfcTextFieldVariant variant,
  ) {
    if (variant == KkfcTextFieldVariant.multiline) {
      return const EdgeInsets.symmetric(
        horizontal: KkfcSpace.space4,
        vertical: KkfcSpace.space3,
      );
    }

    switch (size) {
      case KkfcTextFieldSize.large:
        return const EdgeInsets.symmetric(
          horizontal: KkfcSpace.space4,
          vertical: KkfcSpace.space4,
        );
      case KkfcTextFieldSize.standard:
        return const EdgeInsets.symmetric(
          horizontal: KkfcSpace.space4,
          vertical: KkfcSpace.space3,
        );
      case KkfcTextFieldSize.compact:
        return const EdgeInsets.symmetric(
          horizontal: KkfcSpace.space3,
          vertical: KkfcSpace.space2,
        );
    }
  }

  static BorderRadius _resolveRadius(KkfcTextFieldShape shape) {
    switch (shape) {
      case KkfcTextFieldShape.rounded:
        return BorderRadius.circular(KkfcRadius.md); // 10.0
      case KkfcTextFieldShape.pill:
        return BorderRadius.circular(KkfcRadius.pill); // 999.0
      case KkfcTextFieldShape.borderless:
        return BorderRadius.zero;
    }
  }
}
