import 'package:flutter/material.dart';

import 'button_types.dart';
import 'types/ghost_button.dart';
import 'types/icon_button.dart';
import 'types/outlined_button.dart';
import 'types/primary_button.dart';
import 'types/split_button.dart';
import 'types/subtle_button.dart';

/// Unified KKFC button component adhering to the KKFC design system.
///
/// Provides specialized factories for each button variant:
/// - [KkfcButton.primary]: Solid copper action button ("do this next").
/// - [KkfcButton.outlined]: 1px outlined button (action, danger, dashed, badge).
/// - [KkfcButton.subtle]: Warm sand / sunken neutral filled button (e.g. "Edit prices").
/// - [KkfcButton.ghost]: Borderless text/link button (link, danger, subtle).
/// - [KkfcButton.split]: Dual-aligned button with label and trailing price/value.
/// - [KkfcButton.icon]: Square/rounded icon-only button (e.g. "✕", "🔄").
class KkfcButton extends StatelessWidget {
  const KkfcButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = KkfcButtonVariant.primary,
    this.intent = KkfcButtonIntent.action,
    this.size = KkfcButtonSize.standard,
    this.borderStyle = KkfcBorderStyle.solid,
    this.prominent = true,
    this.leadingIcon,
    this.trailingIcon,
    this.trailingText,
    this.badge,
    this.underline = false,
    this.isLoading = false,
    this.loadingLabel,
    this.fullWidth = false,
    this.customBackground,
    this.customForeground,
    this.customRadius,
    this.focusNode,
  });

  /// Factory for solid copper primary action button.
  const factory KkfcButton.primary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    Widget? leadingIcon,
    Widget? trailingIcon,
    String? trailingText,
    Widget? badge,
    KkfcButtonSize size,
    bool isLoading,
    String? loadingLabel,
    bool fullWidth,
    Color? customBackground,
    Color? customForeground,
    BorderRadius? customRadius,
    FocusNode? focusNode,
  }) = _KkfcPrimaryButtonWrapper;

  /// Factory for 1px outlined button.
  const factory KkfcButton.outlined({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    KkfcButtonIntent intent,
    KkfcBorderStyle borderStyle,
    bool prominent,
    Widget? leadingIcon,
    Widget? trailingIcon,
    String? trailingText,
    Widget? badge,
    KkfcButtonSize size,
    bool isLoading,
    String? loadingLabel,
    bool fullWidth,
    Color? customBackground,
    Color? customForeground,
    BorderRadius? customRadius,
    FocusNode? focusNode,
  }) = _KkfcOutlinedButtonWrapper;

  /// Factory for warm sand subtle/tonal button.
  const factory KkfcButton.subtle({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    Widget? leadingIcon,
    Widget? trailingIcon,
    KkfcButtonSize size,
    bool isLoading,
    String? loadingLabel,
    bool fullWidth,
    Color? customBackground,
    Color? customForeground,
    FocusNode? focusNode,
  }) = _KkfcSubtleButtonWrapper;

  /// Factory for borderless ghost/text button.
  const factory KkfcButton.ghost({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    KkfcButtonIntent intent,
    Color? textColor,
    bool underline,
    Widget? leadingIcon,
    Widget? trailingIcon,
    KkfcButtonSize size,
    bool isLoading,
    String? loadingLabel,
    bool fullWidth,
    FocusNode? focusNode,
  }) = _KkfcGhostButtonWrapper;

  /// Factory for dual-sided split button with label and trailing price/value.
  const factory KkfcButton.split({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    String? trailingValue,
    Widget? leadingIcon,
    Widget? trailingIcon,
    KkfcButtonVariant variant,
    KkfcButtonIntent intent,
    KkfcButtonSize size,
    bool isLoading,
    String? loadingLabel,
    bool fullWidth,
    Color? customBackground,
    Color? customForeground,
    BorderRadius? customRadius,
    FocusNode? focusNode,
  }) = _KkfcSplitButtonWrapper;

  /// Factory for icon-only button.
  const factory KkfcButton.icon({
    Key? key,
    required Widget icon,
    required VoidCallback? onPressed,
    KkfcButtonVariant variant,
    KkfcButtonIntent intent,
    KkfcButtonSize size,
    KkfcBorderStyle borderStyle,
    bool prominent,
    bool isLoading,
    Color? customBackground,
    Color? customForeground,
    BorderRadius? customRadius,
    String? tooltip,
    FocusNode? focusNode,
  }) = _KkfcIconButtonWrapper;

  final String label;
  final VoidCallback? onPressed;
  final KkfcButtonVariant variant;
  final KkfcButtonIntent intent;
  final KkfcButtonSize size;
  final KkfcBorderStyle borderStyle;
  final bool prominent;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final String? trailingText;
  final Widget? badge;
  final bool underline;
  final bool isLoading;
  final String? loadingLabel;
  final bool fullWidth;
  final Color? customBackground;
  final Color? customForeground;
  final BorderRadius? customRadius;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case KkfcButtonVariant.primary:
        return KkfcPrimaryButton(
          label: label,
          onPressed: onPressed,
          leadingIcon: leadingIcon,
          trailingIcon: trailingIcon,
          trailingText: trailingText,
          badge: badge,
          size: size,
          isLoading: isLoading,
          loadingLabel: loadingLabel,
          fullWidth: fullWidth,
          customBackground: customBackground,
          customForeground: customForeground,
          customRadius: customRadius,
          focusNode: focusNode,
        );

      case KkfcButtonVariant.outlined:
        return KkfcOutlinedButton(
          label: label,
          onPressed: onPressed,
          intent: intent,
          borderStyle: borderStyle,
          prominent: prominent,
          leadingIcon: leadingIcon,
          trailingIcon: trailingIcon,
          trailingText: trailingText,
          badge: badge,
          size: size,
          isLoading: isLoading,
          loadingLabel: loadingLabel,
          fullWidth: fullWidth,
          customBackground: customBackground,
          customForeground: customForeground,
          customRadius: customRadius,
          focusNode: focusNode,
        );

      case KkfcButtonVariant.subtle:
        return KkfcSubtleButton(
          label: label,
          onPressed: onPressed,
          leadingIcon: leadingIcon,
          trailingIcon: trailingIcon,
          size: size,
          isLoading: isLoading,
          loadingLabel: loadingLabel,
          fullWidth: fullWidth,
          customBackground: customBackground,
          customForeground: customForeground,
          focusNode: focusNode,
        );

      case KkfcButtonVariant.ghost:
        return KkfcGhostButton(
          label: label,
          onPressed: onPressed,
          intent: intent,
          textColor: customForeground,
          underline: underline,
          leadingIcon: leadingIcon,
          trailingIcon: trailingIcon,
          size: size,
          isLoading: isLoading,
          loadingLabel: loadingLabel,
          fullWidth: fullWidth,
          focusNode: focusNode,
        );

      case KkfcButtonVariant.split:
        return KkfcSplitButton(
          label: label,
          onPressed: onPressed,
          trailingValue: trailingText,
          leadingIcon: leadingIcon,
          trailingIcon: trailingIcon,
          variant: variant,
          intent: intent,
          size: size,
          isLoading: isLoading,
          loadingLabel: loadingLabel,
          fullWidth: fullWidth,
          customBackground: customBackground,
          customForeground: customForeground,
          customRadius: customRadius,
          focusNode: focusNode,
        );
    }
  }
}

class _KkfcPrimaryButtonWrapper extends KkfcButton {
  const _KkfcPrimaryButtonWrapper({
    super.key,
    required super.label,
    required super.onPressed,
    super.leadingIcon,
    super.trailingIcon,
    super.trailingText,
    super.badge,
    super.size = KkfcButtonSize.standard,
    super.isLoading = false,
    super.loadingLabel,
    super.fullWidth = false,
    super.customBackground,
    super.customForeground,
    super.customRadius,
    super.focusNode,
  }) : super(variant: KkfcButtonVariant.primary);
}

class _KkfcOutlinedButtonWrapper extends KkfcButton {
  const _KkfcOutlinedButtonWrapper({
    super.key,
    required super.label,
    required super.onPressed,
    super.intent = KkfcButtonIntent.action,
    super.borderStyle = KkfcBorderStyle.solid,
    super.prominent = true,
    super.leadingIcon,
    super.trailingIcon,
    super.trailingText,
    super.badge,
    super.size = KkfcButtonSize.standard,
    super.isLoading = false,
    super.loadingLabel,
    super.fullWidth = false,
    super.customBackground,
    super.customForeground,
    super.customRadius,
    super.focusNode,
  }) : super(variant: KkfcButtonVariant.outlined);
}

class _KkfcSubtleButtonWrapper extends KkfcButton {
  const _KkfcSubtleButtonWrapper({
    super.key,
    required super.label,
    required super.onPressed,
    super.leadingIcon,
    super.trailingIcon,
    super.size = KkfcButtonSize.standard,
    super.isLoading = false,
    super.loadingLabel,
    super.fullWidth = false,
    super.customBackground,
    super.customForeground,
    super.focusNode,
  }) : super(variant: KkfcButtonVariant.subtle);
}

class _KkfcGhostButtonWrapper extends KkfcButton {
  const _KkfcGhostButtonWrapper({
    super.key,
    required super.label,
    required super.onPressed,
    super.intent = KkfcButtonIntent.action,
    Color? textColor,
    super.underline = false,
    super.leadingIcon,
    super.trailingIcon,
    super.size = KkfcButtonSize.standard,
    super.isLoading = false,
    super.loadingLabel,
    super.fullWidth = false,
    super.focusNode,
  }) : super(variant: KkfcButtonVariant.ghost, customForeground: textColor);
}

class _KkfcSplitButtonWrapper extends KkfcButton {
  const _KkfcSplitButtonWrapper({
    super.key,
    required super.label,
    required super.onPressed,
    String? trailingValue,
    super.leadingIcon,
    super.trailingIcon,
    super.variant = KkfcButtonVariant.primary,
    super.intent = KkfcButtonIntent.action,
    super.size = KkfcButtonSize.primary,
    super.isLoading = false,
    super.loadingLabel,
    super.fullWidth = true,
    super.customBackground,
    super.customForeground,
    super.customRadius,
    super.focusNode,
  }) : super(trailingText: trailingValue);
}

class _KkfcIconButtonWrapper extends KkfcButton {
  const _KkfcIconButtonWrapper({
    super.key,
    required this.icon,
    required super.onPressed,
    super.variant = KkfcButtonVariant.outlined,
    super.intent = KkfcButtonIntent.action,
    super.size = KkfcButtonSize.compact,
    super.borderStyle = KkfcBorderStyle.solid,
    super.prominent = true,
    super.isLoading = false,
    super.customBackground,
    super.customForeground,
    super.customRadius,
    this.tooltip,
    super.focusNode,
  }) : super(label: '');

  final Widget icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return KkfcIconButton(
      icon: icon,
      onPressed: onPressed,
      variant: variant,
      intent: intent,
      size: size,
      borderStyle: borderStyle,
      prominent: prominent,
      isLoading: isLoading,
      customBackground: customBackground,
      customForeground: customForeground,
      customRadius: customRadius,
      tooltip: tooltip,
      focusNode: focusNode,
    );
  }
}
