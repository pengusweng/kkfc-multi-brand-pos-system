import 'package:flutter/foundation.dart';

/// Interactive states a button can be in.
enum KkfcButtonState {
  idle,
  hovered,
  pressed,
  focused,
  disabled,
  loading,
}

/// Holds the runtime interactive state of a KKFC button.
@immutable
class KkfcButtonStateContext {
  const KkfcButtonStateContext({
    this.isDisabled = false,
    this.isLoading = false,
    this.isPressed = false,
    this.isHovered = false,
    this.isFocused = false,
  });

  final bool isDisabled;
  final bool isLoading;
  final bool isPressed;
  final bool isHovered;
  final bool isFocused;

  /// Whether the button can respond to user taps.
  bool get isInteractive => !isDisabled && !isLoading;

  /// Primary state name for diagnostics or styling.
  KkfcButtonState get currentState {
    if (isLoading) return KkfcButtonState.loading;
    if (isDisabled) return KkfcButtonState.disabled;
    if (isPressed) return KkfcButtonState.pressed;
    if (isHovered) return KkfcButtonState.hovered;
    if (isFocused) return KkfcButtonState.focused;
    return KkfcButtonState.idle;
  }

  KkfcButtonStateContext copyWith({
    bool? isDisabled,
    bool? isLoading,
    bool? isPressed,
    bool? isHovered,
    bool? isFocused,
  }) {
    return KkfcButtonStateContext(
      isDisabled: isDisabled ?? this.isDisabled,
      isLoading: isLoading ?? this.isLoading,
      isPressed: isPressed ?? this.isPressed,
      isHovered: isHovered ?? this.isHovered,
      isFocused: isFocused ?? this.isFocused,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KkfcButtonStateContext &&
          runtimeType == other.runtimeType &&
          isDisabled == other.isDisabled &&
          isLoading == other.isLoading &&
          isPressed == other.isPressed &&
          isHovered == other.isHovered &&
          isFocused == other.isFocused;

  @override
  int get hashCode => Object.hash(
        isDisabled,
        isLoading,
        isPressed,
        isHovered,
        isFocused,
      );
}
