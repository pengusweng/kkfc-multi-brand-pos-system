import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';

/// Password field with integrated "Show" / "Hide" action button
/// matching the KKFC design system.
class LoginPasswordField extends StatefulWidget {
  const LoginPasswordField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.hasError = false,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;

  @override
  State<LoginPasswordField> createState() => _LoginPasswordFieldState();
}

class _LoginPasswordFieldState extends State<LoginPasswordField> {
  bool _visible = false;
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_isFocused != _focusNode.hasFocus) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    double borderWidth;

    if (widget.hasError) {
      borderColor = KkfcColors.danger; // #B3261E
      borderWidth = KkfcBorderWidth.thick; // 2.0
    } else if (_isFocused) {
      borderColor = KkfcColors.focus; // #1F66C9
      borderWidth = KkfcBorderWidth.thick; // 2.0
    } else if (!widget.enabled) {
      borderColor = KkfcColors.border; // #DDD6C9
      borderWidth = KkfcBorderWidth.thin;
    } else {
      borderColor = KkfcColors.borderStrong; // #76849A
      borderWidth = KkfcBorderWidth.thin;
    }

    final hintStyle = KkfcTypography.textBase.copyWith(
      color: KkfcColors.ink3,
      fontWeight: KkfcFontWeights.regular,
    );

    final inputStyle = KkfcTypography.textBase.copyWith(
      color: widget.enabled ? KkfcColors.ink : KkfcColors.ink3,
      fontWeight: KkfcFontWeights.regular,
    );

    return Container(
      height: KkfcTargets.posMinimum, // 48.0
      decoration: BoxDecoration(
        color: widget.enabled
            ? KkfcColors.surface
            : KkfcColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(KkfcRadius.md),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              obscureText: !_visible,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onChanged: widget.onChanged,
              onSubmitted: (_) => widget.onSubmitted?.call(),
              style: inputStyle,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: KkfcSpace.space4,
                  vertical: KkfcSpace.space3,
                ),
                hintText: 'Enter password',
                hintStyle: hintStyle,
              ),
            ),
          ),
          Container(
            width: borderWidth,
            color: borderColor,
          ),
          SizedBox(
            width: 68.0,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(9.0),
                  ),
                ),
                foregroundColor: KkfcColors.ink,
              ),
              onPressed: widget.enabled
                  ? () => setState(() => _visible = !_visible)
                  : null,
              child: Text(
                _visible ? 'Hide' : 'Show',
                style: KkfcTypography.textSm.copyWith(
                  color: widget.enabled ? KkfcColors.ink : KkfcColors.ink3,
                  fontWeight: KkfcFontWeights.medium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
