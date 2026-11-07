/// Button types and configurations for KKFC design system.
enum KkfcButtonVariant {
  /// Solid copper action button ("do this next"). One primary per screen state.
  primary,

  /// Outlined border button on transparent/surface background.
  outlined,

  /// Warm sand / sunken neutral filled button (e.g. "Edit prices").
  subtle,

  /// Borderless text/link button.
  ghost,

  /// Dual-sided button with left label and right value/price/chevron.
  split,
}

/// Intent conveys the semantic purpose of the button.
enum KkfcButtonIntent {
  /// Standard action (Copper for primary, ink for outlined/ghost).
  action,

  /// Destructive or failure action (Danger red text & border).
  danger,

  /// Neutral / low-emphasis action (Slate/muted text).
  neutral,
}

/// Pre-defined sizes aligned with touch target tokens.
enum KkfcButtonSize {
  /// POS Primary target: 56px height, spacious padding.
  primary,

  /// POS Minimum target: 48px height (default for most actions).
  standard,

  /// Web control target: 40px height for dense/table controls.
  compact,

  /// Dense target: 32px height for chips and meta actions.
  small,
}

/// Border styling for outlined buttons.
enum KkfcBorderStyle {
  /// 1px solid stroke.
  solid,

  /// 1px dashed stroke (e.g. "+ Add ingredient").
  dashed,

  /// No stroke.
  none,
}
