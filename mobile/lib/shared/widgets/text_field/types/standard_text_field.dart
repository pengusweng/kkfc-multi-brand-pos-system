import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../states/text_field_container.dart';
import '../states/text_field_state.dart';
import '../text_field_style.dart';
import '../text_field_types.dart';

/// Standard single-line outlined text input for the KKFC design system.
/// Supports resting, focused (blue #1F66C9), error (red #B3261E), and disabled states.
class KkfcStandardTextField extends StatelessWidget {
  const KkfcStandardTextField({
    super.key,
    this.label,
    this.controller,
    this.focusNode,
    this.hint,
    this.helperText,
    this.errorText,
    this.disabledText,
    this.hasError = false,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.valueStyle,
    this.obscureText = false,
    this.autocorrect = true,
    this.autofocus = false,
    this.prefix,
    this.suffix,
    this.size = KkfcTextFieldSize.standard,
    this.shape = KkfcTextFieldShape.rounded,
    this.customBackground,
    this.customForeground,
    this.customRadius,
  });

  final String? label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final String? disabledText;
  final bool hasError;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;
  final TextStyle? valueStyle;
  final bool obscureText;
  final bool autocorrect;
  final bool autofocus;
  final Widget? prefix;
  final Widget? suffix;
  final KkfcTextFieldSize size;
  final KkfcTextFieldShape shape;
  final Color? customBackground;
  final Color? customForeground;
  final BorderRadius? customRadius;

  @override
  Widget build(BuildContext context) {
    final showError = hasError || (errorText != null && errorText!.isNotEmpty);

    final idleStyle = KkfcTextFieldStyleResolver.resolve(
      variant: KkfcTextFieldVariant.standard,
      state: KkfcTextFieldStateContext(isEnabled: enabled, hasError: showError),
      size: size,
      shape: shape,
      customBackground: customBackground,
      customForeground: customForeground,
      customRadius: customRadius,
      customTextStyle: valueStyle,
    );

    final focusedStyle = KkfcTextFieldStyleResolver.resolve(
      variant: KkfcTextFieldVariant.standard,
      state: KkfcTextFieldStateContext(
        isFocused: true,
        hasError: showError,
        isEnabled: enabled,
      ),
      size: size,
      shape: shape,
      customBackground: customBackground,
      customForeground: customForeground,
      customRadius: customRadius,
      customTextStyle: valueStyle,
    );

    final errorStyle = KkfcTextFieldStyleResolver.resolve(
      variant: KkfcTextFieldVariant.standard,
      state: KkfcTextFieldStateContext(hasError: true, isEnabled: enabled),
      size: size,
      shape: shape,
      customBackground: customBackground,
      customForeground: customForeground,
      customRadius: customRadius,
      customTextStyle: valueStyle,
    );

    final disabledStyle = KkfcTextFieldStyleResolver.resolve(
      variant: KkfcTextFieldVariant.standard,
      state: const KkfcTextFieldStateContext(isEnabled: false),
      size: size,
      shape: shape,
      customBackground: customBackground,
      customForeground: customForeground,
      customRadius: customRadius,
      customTextStyle: valueStyle,
    );

    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      obscureText: obscureText,
      autocorrect: autocorrect,
      enableSuggestions: !obscureText,
      inputFormatters: inputFormatters,
      textAlign: textAlign,
      style: idleStyle.textStyle,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: idleStyle.backgroundColor,
        hintText: enabled ? hint : (disabledText ?? hint),
        hintStyle: idleStyle.hintStyle,
        contentPadding: idleStyle.contentPadding,
        prefixIcon: prefix,
        suffixIcon: suffix,
        constraints: idleStyle.height != null
            ? BoxConstraints(minHeight: idleStyle.height!)
            : null,
        enabledBorder: showError
            ? errorStyle.toOutlineInputBorder()
            : idleStyle.toOutlineInputBorder(),
        focusedBorder: showError
            ? errorStyle.toOutlineInputBorder()
            : focusedStyle.toOutlineInputBorder(),
        errorBorder: errorStyle.toOutlineInputBorder(),
        focusedErrorBorder: errorStyle.toOutlineInputBorder(),
        disabledBorder: disabledStyle.toOutlineInputBorder(),
      ),
    );

    return KkfcFormFieldContainer(
      label: label,
      helperText: helperText,
      errorText: errorText,
      hasError: showError,
      child: field,
    );
  }
}
