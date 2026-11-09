import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../states/text_field_container.dart';
import '../states/text_field_state.dart';
import '../text_field_style.dart';
import '../text_field_types.dart';

/// Numeric text input formatted with tabular numerals.
/// Used for counts, quantities, amounts, and table numbers.
class KkfcNumericField extends StatelessWidget {
  const KkfcNumericField({
    super.key,
    this.label,
    this.controller,
    this.focusNode,
    this.hint,
    this.helperText,
    this.errorText,
    this.hasError = false,
    this.enabled = true,
    this.isBold = true,
    this.allowDecimal = false,
    this.textAlign = TextAlign.center,
    this.size = KkfcTextFieldSize.standard,
    this.width,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.valueStyle,
  });

  final String? label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final bool hasError;
  final bool enabled;
  final bool isBold;
  final bool allowDecimal;
  final TextAlign textAlign;
  final KkfcTextFieldSize size;
  final double? width;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final showError = hasError || (errorText != null && errorText!.isNotEmpty);

    final idleStyle = KkfcTextFieldStyleResolver.resolve(
      variant: KkfcTextFieldVariant.numeric,
      state: KkfcTextFieldStateContext(isEnabled: enabled, hasError: showError),
      size: size,
      isNumeric: true,
      isBold: isBold,
      textAlign: textAlign,
      customTextStyle: valueStyle,
    );

    final focusedStyle = KkfcTextFieldStyleResolver.resolve(
      variant: KkfcTextFieldVariant.numeric,
      state: KkfcTextFieldStateContext(
        isFocused: true,
        hasError: showError,
        isEnabled: enabled,
      ),
      size: size,
      isNumeric: true,
      isBold: isBold,
      textAlign: textAlign,
      customTextStyle: valueStyle,
    );

    final errorStyle = KkfcTextFieldStyleResolver.resolve(
      variant: KkfcTextFieldVariant.numeric,
      state: KkfcTextFieldStateContext(hasError: true, isEnabled: enabled),
      size: size,
      isNumeric: true,
      isBold: isBold,
      textAlign: textAlign,
      customTextStyle: valueStyle,
    );

    final disabledStyle = KkfcTextFieldStyleResolver.resolve(
      variant: KkfcTextFieldVariant.numeric,
      state: const KkfcTextFieldStateContext(isEnabled: false),
      size: size,
      isNumeric: true,
      isBold: isBold,
      textAlign: textAlign,
      customTextStyle: valueStyle,
    );

    Widget field = TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      textAlign: textAlign,
      style: idleStyle.textStyle,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      inputFormatters:
          inputFormatters ??
          [
            FilteringTextInputFormatter.allow(
              allowDecimal ? RegExp(r'^\d*\.?\d*') : RegExp(r'^\d*'),
            ),
          ],
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: idleStyle.backgroundColor,
        hintText: hint,
        hintStyle: idleStyle.hintStyle,
        contentPadding: idleStyle.contentPadding,
        constraints: idleStyle.height != null
            ? BoxConstraints(minHeight: idleStyle.height!)
            : null,
        border: idleStyle.toOutlineInputBorder(),
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

    if (width != null) {
      field = SizedBox(width: width, child: field);
    }

    return KkfcFormFieldContainer(
      label: label,
      helperText: helperText,
      errorText: errorText,
      hasError: showError,
      child: field,
    );
  }
}
