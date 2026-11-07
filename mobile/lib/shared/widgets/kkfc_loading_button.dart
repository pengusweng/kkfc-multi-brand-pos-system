import 'package:flutter/material.dart';
import 'button/button.dart';

export 'button/button.dart';

/// Legacy shared loading button updated to use the unified KKFC button system.
/// Preserves full backwards compatibility for all existing call sites and tests.
class KkfcLoadingButton extends StatelessWidget {
  const KkfcLoadingButton({
    super.key,
    required this.label,
    required this.loadingLabel,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final String loadingLabel;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return KkfcPrimaryButton(
      label: label,
      loadingLabel: loadingLabel,
      isLoading: isLoading,
      onPressed: onPressed,
      fullWidth: true,
      size: KkfcButtonSize.primary,
    );
  }
}
