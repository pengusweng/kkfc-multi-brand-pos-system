import 'package:flutter/foundation.dart';

import '../text_field_types.dart';

/// Holds the runtime interactive state of a KKFC text field.
@immutable
class KkfcTextFieldStateContext {
  const KkfcTextFieldStateContext({
    this.isFocused = false,
    this.hasError = false,
    this.isEnabled = true,
    this.isHovered = false,
  });

  final bool isFocused;
  final bool hasError;
  final bool isEnabled;
  final bool isHovered;

  /// Current visual state with clear precedence:
  /// disabled > error > focused > idle.
  KkfcTextFieldState get currentState {
    if (!isEnabled) return KkfcTextFieldState.disabled;
    if (hasError) return KkfcTextFieldState.error;
    if (isFocused) return KkfcTextFieldState.focused;
    return KkfcTextFieldState.idle;
  }

  KkfcTextFieldStateContext copyWith({
    bool? isFocused,
    bool? hasError,
    bool? isEnabled,
    bool? isHovered,
  }) {
    return KkfcTextFieldStateContext(
      isFocused: isFocused ?? this.isFocused,
      hasError: hasError ?? this.hasError,
      isEnabled: isEnabled ?? this.isEnabled,
      isHovered: isHovered ?? this.isHovered,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KkfcTextFieldStateContext &&
          runtimeType == other.runtimeType &&
          isFocused == other.isFocused &&
          hasError == other.hasError &&
          isEnabled == other.isEnabled &&
          isHovered == other.isHovered;

  @override
  int get hashCode => Object.hash(isFocused, hasError, isEnabled, isHovered);
}
