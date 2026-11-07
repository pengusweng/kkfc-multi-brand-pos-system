import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import '../button_state.dart';
import '../button_style.dart';
import '../button_types.dart';
import '../states/button_interactive.dart';
import '../states/button_loading_state.dart';

/// Borderless text/ghost button (link, danger text, action text, or subtle action).
class KkfcGhostButton extends StatelessWidget {
  const KkfcGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.intent = KkfcButtonIntent.action,
    this.textColor,
    this.underline = false,
    this.leadingIcon,
    this.trailingIcon,
    this.size = KkfcButtonSize.standard,
    this.isLoading = false,
    this.loadingLabel,
    this.fullWidth = false,
    this.focusNode,
  });

  final String label;
  final VoidCallback? onPressed;
  final KkfcButtonIntent intent;
  final Color? textColor;
  final bool underline;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final KkfcButtonSize size;
  final bool isLoading;
  final String? loadingLabel;
  final bool fullWidth;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final isInteractive = onPressed != null && !isLoading;
    final style = KkfcButtonStyleResolver.resolve(
      variant: KkfcButtonVariant.ghost,
      intent: intent,
      size: size,
      borderStyle: KkfcBorderStyle.none,
      state: KkfcButtonStateContext(
        isDisabled: onPressed == null,
        isLoading: isLoading,
      ),
      customForeground: textColor,
    );

    var textStyle = style.textStyle;
    if (underline) {
      textStyle = textStyle.copyWith(
        decoration: TextDecoration.underline,
        decorationColor: style.foregroundColor,
      );
    }

    Widget button = TextButton(
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
          if (states.contains(WidgetState.disabled)) {
            return Colors.transparent;
          }
          if (states.contains(WidgetState.pressed)) {
            return const Color(0x1419293E);
          }
          if (states.contains(WidgetState.hovered)) {
            return const Color(0x0A19293E);
          }
          return Colors.transparent;
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
        idleContent: _buildIdleContent(style, textStyle),
        loadingLabel: loadingLabel,
        foregroundColor: style.foregroundColor,
        iconSize: style.iconSize,
        textStyle: textStyle,
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

  Widget _buildIdleContent(
    KkfcResolvedButtonStyle style,
    TextStyle textStyle,
  ) {
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
          style: textStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

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
