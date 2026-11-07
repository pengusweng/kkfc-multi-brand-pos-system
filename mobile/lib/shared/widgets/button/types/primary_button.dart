import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import '../button_state.dart';
import '../button_style.dart';
import '../button_types.dart';
import '../states/button_interactive.dart';
import '../states/button_loading_state.dart';

/// Solid copper action button ("do this next").
/// Primary call to action per screen state, matching the KKFC colour language.
class KkfcPrimaryButton extends StatelessWidget {
  const KkfcPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
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
      variant: KkfcButtonVariant.primary,
      intent: KkfcButtonIntent.action,
      size: size,
      borderStyle: KkfcBorderStyle.none,
      state: KkfcButtonStateContext(
        isDisabled: onPressed == null,
        isLoading: isLoading,
      ),
      customBackground: customBackground,
      customForeground: customForeground,
      customRadius: customRadius,
    );

    Widget button = FilledButton(
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
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (isLoading) {
            return customBackground ?? KkfcColors.action;
          }
          if (states.contains(WidgetState.disabled)) {
            // Muted copper for disabled primary action
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
          return customForeground ?? KkfcColors.onSolid;
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
