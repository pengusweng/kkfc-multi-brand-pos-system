import 'package:flutter/material.dart';

import '../states/text_field_container.dart';
import '../states/text_field_state.dart';
import '../text_field_style.dart';
import '../text_field_types.dart';

/// Multi-line text input for notes, reasons, and descriptions.
class KkfcTextArea extends StatelessWidget {
  const KkfcTextArea({
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
    this.minLines = 3,
    this.maxLines = 6,
    this.minHeight = 84.0,
    this.onChanged,
    this.valueStyle,
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
  final int minLines;
  final int? maxLines;
  final double minHeight;
  final ValueChanged<String>? onChanged;
  final TextStyle? valueStyle;
  final Color? customBackground;
  final Color? customForeground;
  final BorderRadius? customRadius;

  @override
  Widget build(BuildContext context) {
    final showError = hasError || (errorText != null && errorText!.isNotEmpty);

    final idleStyle = KkfcTextFieldStyleResolver.resolve(
      variant: KkfcTextFieldVariant.multiline,
      state: KkfcTextFieldStateContext(isEnabled: enabled, hasError: showError),
      customBackground: customBackground,
      customForeground: customForeground,
      customRadius: customRadius,
      customTextStyle: valueStyle,
    );

    final focusedStyle = KkfcTextFieldStyleResolver.resolve(
      variant: KkfcTextFieldVariant.multiline,
      state: KkfcTextFieldStateContext(
        isFocused: true,
        hasError: showError,
        isEnabled: enabled,
      ),
      customBackground: customBackground,
      customForeground: customForeground,
      customRadius: customRadius,
      customTextStyle: valueStyle,
    );

    final errorStyle = KkfcTextFieldStyleResolver.resolve(
      variant: KkfcTextFieldVariant.multiline,
      state: KkfcTextFieldStateContext(hasError: true, isEnabled: enabled),
      customBackground: customBackground,
      customForeground: customForeground,
      customRadius: customRadius,
      customTextStyle: valueStyle,
    );

    final disabledStyle = KkfcTextFieldStyleResolver.resolve(
      variant: KkfcTextFieldVariant.multiline,
      state: const KkfcTextFieldStateContext(isEnabled: false),
      customBackground: customBackground,
      customForeground: customForeground,
      customRadius: customRadius,
      customTextStyle: valueStyle,
    );

    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: TextInputType.multiline,
      onChanged: onChanged,
      style: idleStyle.textStyle,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: idleStyle.backgroundColor,
        hintText: enabled ? hint : (disabledText ?? hint),
        hintStyle: idleStyle.hintStyle,
        contentPadding: idleStyle.contentPadding,
        constraints: BoxConstraints(minHeight: minHeight),
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
