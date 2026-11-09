import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';

import '../states/text_field_container.dart';
import '../states/text_field_state.dart';
import '../text_field_style.dart';
import '../text_field_types.dart';

/// Search input matching the design system.
/// Supports pill shape (default), rounded, or borderless / ghost styling.
class KkfcSearchField extends StatefulWidget {
  const KkfcSearchField({
    super.key,
    this.label,
    this.controller,
    this.focusNode,
    this.hint = 'Search',
    this.shape = KkfcTextFieldShape.pill,
    this.size = KkfcTextFieldSize.compact,
    this.showLeadingIcon = false,
    this.showClearButton = true,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.enabled = true,
    this.autofocus = false,
    this.customBackground,
    this.customForeground,
  });

  final String? label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hint;
  final KkfcTextFieldShape shape;
  final KkfcTextFieldSize size;
  final bool showLeadingIcon;
  final bool showClearButton;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool enabled;
  final bool autofocus;
  final Color? customBackground;
  final Color? customForeground;

  @override
  State<KkfcSearchField> createState() => _KkfcSearchFieldState();
}

class _KkfcSearchFieldState extends State<KkfcSearchField> {
  late TextEditingController _controller;
  bool _internalController = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _controller = TextEditingController();
      _internalController = true;
    } else {
      _controller = widget.controller!;
    }
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_handleTextChange);
  }

  @override
  void didUpdateWidget(KkfcSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (_internalController) {
        _controller.dispose();
        _internalController = false;
      }
      _controller = widget.controller ?? TextEditingController();
      _internalController = widget.controller == null;
      _controller.addListener(_handleTextChange);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChange);
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleTextChange() {
    final hasText = _controller.text.isNotEmpty;
    if (_hasText != hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _handleClear() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final idleStyle = KkfcTextFieldStyleResolver.resolve(
      variant: KkfcTextFieldVariant.search,
      state: KkfcTextFieldStateContext(isEnabled: widget.enabled),
      size: widget.size,
      shape: widget.shape,
      customBackground: widget.customBackground,
      customForeground: widget.customForeground,
    );

    final focusedStyle = KkfcTextFieldStyleResolver.resolve(
      variant: KkfcTextFieldVariant.search,
      state: KkfcTextFieldStateContext(
        isFocused: true,
        isEnabled: widget.enabled,
      ),
      size: widget.size,
      shape: widget.shape,
      customBackground: widget.customBackground,
      customForeground: widget.customForeground,
    );

    Widget? leading;
    if (widget.showLeadingIcon) {
      leading = Icon(
        Icons.search,
        size: 18.0,
        color: idleStyle.hintStyle.color,
      );
    }

    Widget? trailing;
    if (widget.showClearButton && _hasText && widget.enabled) {
      trailing = IconButton(
        icon: const Icon(Icons.close, size: 16.0),
        color: idleStyle.hintStyle.color,
        splashRadius: 16.0,
        onPressed: _handleClear,
      );
    }

    final field = TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      style: idleStyle.textStyle,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: idleStyle.backgroundColor,
        hintText: widget.hint,
        hintStyle: idleStyle.hintStyle,
        contentPadding: EdgeInsets.symmetric(
          horizontal: (widget.shape == KkfcTextFieldShape.pill)
              ? KkfcSpace.space4
              : KkfcSpace.space3,
          vertical: KkfcSpace.space2,
        ),
        prefixIcon: leading,
        suffixIcon: trailing,
        constraints: idleStyle.height != null
            ? BoxConstraints(minHeight: idleStyle.height!)
            : null,
        border: idleStyle.toOutlineInputBorder(),
        enabledBorder: idleStyle.toOutlineInputBorder(),
        focusedBorder: focusedStyle.toOutlineInputBorder(),
        disabledBorder: idleStyle.toOutlineInputBorder(),
      ),
    );

    return KkfcFormFieldContainer(label: widget.label, child: field);
  }
}
