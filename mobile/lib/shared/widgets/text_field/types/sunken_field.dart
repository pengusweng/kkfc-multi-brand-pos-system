import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import '../states/text_field_container.dart';
import '../states/text_field_state.dart';
import '../text_field_style.dart';
import '../text_field_types.dart';

/// Read-only / static display field with a warm sand sunken background.
/// Used for reference codes (REF-PACK, REF-REC-01) and system notices.
class KkfcSunkenField extends StatelessWidget {
  const KkfcSunkenField({
    super.key,
    this.label,
    required this.text,
    this.size = KkfcTextFieldSize.standard,
    this.isMonospace = false,
    this.isBold = true,
    this.prefix,
    this.suffix,
    this.padding,
  });

  final String? label;
  final String text;
  final KkfcTextFieldSize size;
  final bool isMonospace;
  final bool isBold;
  final Widget? prefix;
  final Widget? suffix;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final resolvedStyle = KkfcTextFieldStyleResolver.resolve(
      variant: KkfcTextFieldVariant.sunken,
      state: const KkfcTextFieldStateContext(
        isEnabled: false,
      ),
      size: size,
      isBold: isBold,
    );

    final textStyle = isMonospace
        ? resolvedStyle.textStyle.copyWith(fontFamily: KkfcFonts.systemMono)
        : resolvedStyle.textStyle;

    final field = Container(
      constraints: resolvedStyle.height != null
          ? BoxConstraints(minHeight: resolvedStyle.height!)
          : null,
      padding: padding ?? resolvedStyle.contentPadding,
      decoration: BoxDecoration(
        color: resolvedStyle.backgroundColor,
        borderRadius: resolvedStyle.borderRadius,
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          if (prefix != null) ...[
            prefix!,
            const SizedBox(width: KkfcSpace.space2),
          ],
          Expanded(
            child: Text(
              text,
              style: textStyle,
            ),
          ),
          if (suffix != null) ...[
            const SizedBox(width: KkfcSpace.space2),
            suffix!,
          ],
        ],
      ),
    );

    return KkfcFormFieldContainer(
      label: label,
      child: field,
    );
  }
}
