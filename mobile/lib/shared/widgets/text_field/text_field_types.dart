/// Text field types and configurations for the KKFC design system.
enum KkfcTextFieldVariant {
  /// Standard single-line text input (names, codes, values).
  standard,

  /// Multi-line text area (notes, variance reasons, kitchen feedback).
  multiline,

  /// Search input with search icon (standard, pill, or borderless).
  search,

  /// Tabular numeric input (quantities, amounts, table numbers).
  numeric,

  /// Dropdown or picker selector (channel, category, unit).
  select,

  /// Read-only / static display field with sunken warm sand background.
  sunken,
}

/// Visual interactive states for text fields.
enum KkfcTextFieldState {
  /// Default resting state with 1px border.
  idle,

  /// Active keyboard focus with blue focus ring (--k-focus).
  focused,

  /// Validation error or failure state with red border (--k-danger).
  error,

  /// Non-interactive or read-only state.
  disabled,
}

/// Target heights aligned with POS sizing tokens.
enum KkfcTextFieldSize {
  /// 56px height (POS primary touch target).
  large,

  /// 48px height (POS standard minimum target).
  standard,

  /// 40px height (Web control target for dense layouts).
  compact,
}

/// Border shape for text fields.
enum KkfcTextFieldShape {
  /// Standard rounded rectangle (radius-md: 10px).
  rounded,

  /// Pill shape (radius-pill: 999px) for search inputs and chips.
  pill,

  /// Ghost / borderless field.
  borderless,
}

/// Visual theme for selector dropdowns.
enum KkfcSelectTheme {
  /// Standard light outlined field on white surface.
  outlined,

  /// Warm sand sunken background.
  subtle,

  /// Dark navy shell background (--k-shell: #19293E).
  darkShell,
}
