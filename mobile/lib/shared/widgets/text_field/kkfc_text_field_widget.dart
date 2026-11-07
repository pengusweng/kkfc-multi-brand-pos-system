import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'text_field_types.dart';
import 'types/numeric_field.dart';
import 'types/search_field.dart';
import 'types/select_field.dart';
import 'types/standard_text_field.dart';
import 'types/sunken_field.dart';
import 'types/text_area.dart';

/// Unified KKFC text field component matching the design system.
///
/// Provides specialized factories:
/// - [KkfcTextField.standard]: Single-line outlined input with focus & error rings.
/// - [KkfcTextField.multiline]: Multi-line text area for notes, reasons, and instructions.
/// - [KkfcTextField.search]: Search input supporting pill, rounded, and ghost shapes.
/// - [KkfcTextField.numeric]: Tabular numeric field for counts and amounts.
/// - [KkfcTextField.select]: Dropdown selector (outlined, subtle, or dark shell).
/// - [KkfcTextField.sunken]: Read-only warm sand sunken reference field.
class KkfcTextField extends StatelessWidget {
  const KkfcTextField({
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

  /// Factory for standard single-line outlined input.
  const factory KkfcTextField.standard({
    Key? key,
    String? label,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? hint,
    String? helperText,
    String? errorText,
    String? disabledText,
    bool hasError,
    bool enabled,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Iterable<String>? autofillHints,
    List<TextInputFormatter>? inputFormatters,
    TextAlign textAlign,
    TextStyle? valueStyle,
    bool obscureText,
    bool autocorrect,
    bool autofocus,
    Widget? prefix,
    Widget? suffix,
    KkfcTextFieldSize size,
    KkfcTextFieldShape shape,
    Color? customBackground,
    Color? customForeground,
    BorderRadius? customRadius,
  }) = _KkfcStandardTextFieldWrapper;

  /// Factory for multi-line text area (notes, variance reasons, kitchen feedback).
  const factory KkfcTextField.multiline({
    Key? key,
    String? label,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? hint,
    String? helperText,
    String? errorText,
    String? disabledText,
    bool hasError,
    bool enabled,
    int minLines,
    int? maxLines,
    double minHeight,
    ValueChanged<String>? onChanged,
    TextStyle? valueStyle,
    Color? customBackground,
    Color? customForeground,
    BorderRadius? customRadius,
  }) = _KkfcTextAreaWrapper;

  /// Factory for search inputs (pill shape by default).
  const factory KkfcTextField.search({
    Key? key,
    String? label,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? hint,
    KkfcTextFieldShape shape,
    KkfcTextFieldSize size,
    bool showLeadingIcon,
    bool showClearButton,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onClear,
    bool enabled,
    bool autofocus,
    Color? customBackground,
    Color? customForeground,
  }) = _KkfcSearchFieldWrapper;

  /// Factory for tabular numeric fields (quantities, counts, amounts).
  const factory KkfcTextField.numeric({
    Key? key,
    String? label,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? hint,
    String? helperText,
    String? errorText,
    bool hasError,
    bool enabled,
    bool isBold,
    bool allowDecimal,
    TextAlign textAlign,
    KkfcTextFieldSize size,
    double? width,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    List<TextInputFormatter>? inputFormatters,
    TextStyle? valueStyle,
  }) = _KkfcNumericFieldWrapper;

  /// Factory for selector dropdowns.
  static Widget select<T>({
    Key? key,
    String? label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    String hint = 'Select an option',
    String? helperText,
    String? errorText,
    bool hasError = false,
    bool enabled = true,
    KkfcTextFieldSize size = KkfcTextFieldSize.standard,
    KkfcSelectTheme selectTheme = KkfcSelectTheme.outlined,
    Widget? prefix,
  }) {
    return KkfcSelectField<T>(
      key: key,
      label: label,
      value: value,
      items: items,
      onChanged: onChanged,
      hint: hint,
      helperText: helperText,
      errorText: errorText,
      hasError: hasError,
      enabled: enabled,
      size: size,
      selectTheme: selectTheme,
      prefix: prefix,
    );
  }

  /// Factory for warm sand sunken display fields.
  const factory KkfcTextField.sunken({
    Key? key,
    String? label,
    required String text,
    KkfcTextFieldSize size,
    bool isMonospace,
    bool isBold,
    Widget? prefix,
    Widget? suffix,
    EdgeInsetsGeometry? padding,
  }) = _KkfcSunkenFieldWrapper;

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
    return KkfcStandardTextField(
      label: label,
      controller: controller,
      focusNode: focusNode,
      hint: hint,
      helperText: helperText,
      errorText: errorText,
      disabledText: disabledText,
      hasError: hasError,
      enabled: enabled,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      textAlign: textAlign,
      valueStyle: valueStyle,
      obscureText: obscureText,
      autocorrect: autocorrect,
      autofocus: autofocus,
      prefix: prefix,
      suffix: suffix,
      size: size,
      shape: shape,
      customBackground: customBackground,
      customForeground: customForeground,
      customRadius: customRadius,
    );
  }
}

class _KkfcStandardTextFieldWrapper extends KkfcTextField {
  const _KkfcStandardTextFieldWrapper({
    super.key,
    super.label,
    super.controller,
    super.focusNode,
    super.hint,
    super.helperText,
    super.errorText,
    super.disabledText,
    super.hasError = false,
    super.enabled = true,
    super.onChanged,
    super.onSubmitted,
    super.keyboardType,
    super.textInputAction,
    super.autofillHints,
    super.inputFormatters,
    super.textAlign = TextAlign.start,
    super.valueStyle,
    super.obscureText = false,
    super.autocorrect = true,
    super.autofocus = false,
    super.prefix,
    super.suffix,
    super.size = KkfcTextFieldSize.standard,
    super.shape = KkfcTextFieldShape.rounded,
    super.customBackground,
    super.customForeground,
    super.customRadius,
  });
}

class _KkfcTextAreaWrapper extends KkfcTextField {
  const _KkfcTextAreaWrapper({
    super.key,
    super.label,
    super.controller,
    super.focusNode,
    super.hint,
    super.helperText,
    super.errorText,
    super.disabledText,
    super.hasError = false,
    super.enabled = true,
    this.minLines = 3,
    this.maxLines = 6,
    this.minHeight = 84.0,
    super.onChanged,
    super.valueStyle,
    super.customBackground,
    super.customForeground,
    super.customRadius,
  });

  final int minLines;
  final int? maxLines;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return KkfcTextArea(
      label: label,
      controller: controller,
      focusNode: focusNode,
      hint: hint,
      helperText: helperText,
      errorText: errorText,
      disabledText: disabledText,
      hasError: hasError,
      enabled: enabled,
      minLines: minLines,
      maxLines: maxLines,
      minHeight: minHeight,
      onChanged: onChanged,
      valueStyle: valueStyle,
      customBackground: customBackground,
      customForeground: customForeground,
      customRadius: customRadius,
    );
  }
}

class _KkfcSearchFieldWrapper extends KkfcTextField {
  const _KkfcSearchFieldWrapper({
    super.key,
    super.label,
    super.controller,
    super.focusNode,
    super.hint = 'Search',
    super.shape = KkfcTextFieldShape.pill,
    super.size = KkfcTextFieldSize.compact,
    this.showLeadingIcon = false,
    this.showClearButton = true,
    super.onChanged,
    super.onSubmitted,
    this.onClear,
    super.enabled = true,
    super.autofocus = false,
    super.customBackground,
    super.customForeground,
  });

  final bool showLeadingIcon;
  final bool showClearButton;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return KkfcSearchField(
      label: label,
      controller: controller,
      focusNode: focusNode,
      hint: hint ?? 'Search',
      shape: shape,
      size: size,
      showLeadingIcon: showLeadingIcon,
      showClearButton: showClearButton,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onClear: onClear,
      enabled: enabled,
      autofocus: autofocus,
      customBackground: customBackground,
      customForeground: customForeground,
    );
  }
}

class _KkfcNumericFieldWrapper extends KkfcTextField {
  const _KkfcNumericFieldWrapper({
    super.key,
    super.label,
    super.controller,
    super.focusNode,
    super.hint,
    super.helperText,
    super.errorText,
    super.hasError = false,
    super.enabled = true,
    this.isBold = true,
    this.allowDecimal = false,
    super.textAlign = TextAlign.center,
    super.size = KkfcTextFieldSize.standard,
    this.width,
    super.onChanged,
    super.onSubmitted,
    super.inputFormatters,
    super.valueStyle,
  });

  final bool isBold;
  final bool allowDecimal;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return KkfcNumericField(
      label: label,
      controller: controller,
      focusNode: focusNode,
      hint: hint,
      helperText: helperText,
      errorText: errorText,
      hasError: hasError,
      enabled: enabled,
      isBold: isBold,
      allowDecimal: allowDecimal,
      textAlign: textAlign,
      size: size,
      width: width,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      inputFormatters: inputFormatters,
      valueStyle: valueStyle,
    );
  }
}

class _KkfcSunkenFieldWrapper extends KkfcTextField {
  const _KkfcSunkenFieldWrapper({
    super.key,
    super.label,
    required this.text,
    super.size = KkfcTextFieldSize.standard,
    this.isMonospace = false,
    this.isBold = true,
    super.prefix,
    super.suffix,
    this.padding,
  });

  final String text;
  final bool isMonospace;
  final bool isBold;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return KkfcSunkenField(
      label: label,
      text: text,
      size: size,
      isMonospace: isMonospace,
      isBold: isBold,
      prefix: prefix,
      suffix: suffix,
      padding: padding,
    );
  }
}
