import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';

/// Container that manages the standard form field layout:
/// - Label above the input
/// - Child input widget
/// - Helper or error message below with smooth animated transition
class KkfcFormFieldContainer extends StatelessWidget {
  const KkfcFormFieldContainer({
    super.key,
    this.label,
    this.helperText,
    this.errorText,
    this.hasError = false,
    required this.child,
  });

  final String? label;
  final String? helperText;
  final String? errorText;
  final bool hasError;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final hasErrorMessage = errorText != null && errorText!.isNotEmpty;
    final message = errorText ?? helperText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null && label!.isNotEmpty) ...[
          ExcludeSemantics(
            child: Text(
              label!,
              style: KkfcTypography.textSm.copyWith(
                fontWeight: KkfcFontWeights.semiBold,
                color: KkfcColors.ink,
              ),
            ),
          ),
          const SizedBox(height: KkfcSpace.space2),
        ],
        child,
        if (message != null && message.isNotEmpty) ...[
          const SizedBox(height: KkfcSpace.space1),
          Semantics(
            liveRegion: hasErrorMessage,
            child: AnimatedSwitcher(
              duration: reduceMotion ? Duration.zero : KkfcMotion.durMicro,
              child: Text(
                message,
                key: ValueKey(message),
                style: KkfcTypography.textXs.copyWith(
                  color: hasErrorMessage ? KkfcColors.danger : KkfcColors.ink3,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
