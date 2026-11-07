import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import '../states/text_field_container.dart';
import '../states/text_field_state.dart';
import '../text_field_style.dart';
import '../text_field_types.dart';

/// Dropdown selector field matching the KKFC text field style.
/// Supports standard outlined, subtle warm sand, and dark navy shell themes.
class KkfcSelectField<T> extends StatelessWidget {
  const KkfcSelectField({
    super.key,
    this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint = 'Select an option',
    this.helperText,
    this.errorText,
    this.hasError = false,
    this.enabled = true,
    this.size = KkfcTextFieldSize.standard,
    this.selectTheme = KkfcSelectTheme.outlined,
    this.prefix,
  });

  final String? label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String hint;
  final String? helperText;
  final String? errorText;
  final bool hasError;
  final bool enabled;
  final KkfcTextFieldSize size;
  final KkfcSelectTheme selectTheme;
  final Widget? prefix;

  @override
  Widget build(BuildContext context) {
    final showError = hasError || (errorText != null && errorText!.isNotEmpty);

    final resolvedStyle = KkfcTextFieldStyleResolver.resolve(
      variant: KkfcTextFieldVariant.select,
      state: KkfcTextFieldStateContext(
        isEnabled: enabled,
        hasError: showError,
      ),
      size: size,
      selectTheme: selectTheme,
    );

    Widget field = Container(
      height: resolvedStyle.height,
      padding: EdgeInsets.symmetric(
        horizontal: (size == KkfcTextFieldSize.compact)
            ? KkfcSpace.space3
            : KkfcSpace.space4,
      ),
      decoration: BoxDecoration(
        color: resolvedStyle.backgroundColor,
        borderRadius: resolvedStyle.borderRadius,
        border: (resolvedStyle.borderWidth > 0)
            ? Border.all(
                color: showError ? KkfcColors.danger : resolvedStyle.borderColor,
                width: showError
                    ? KkfcBorderWidth.thick
                    : resolvedStyle.borderWidth,
              )
            : null,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          hint: Text(hint, style: resolvedStyle.hintStyle),
          style: resolvedStyle.textStyle,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: resolvedStyle.iconColor,
            size: 20.0,
          ),
          dropdownColor: selectTheme == KkfcSelectTheme.darkShell
              ? KkfcColors.shellRaised
              : KkfcColors.surface,
          isExpanded: true,
          focusColor: Colors.transparent,
        ),
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
