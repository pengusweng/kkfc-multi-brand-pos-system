// Color schemes reflecting the "Colour language" design tokens.
import 'package:flutter/material.dart';

import 'color_tokens.dart';

const ColorScheme kkfcCounterScheme = ColorScheme(
  brightness: Brightness.light,
  primary: KkfcColors.selected, // --k-selected (#1D2940)
  onPrimary: KkfcColors.onSelected, // --k-on-selected (#FFFFFF, 14.55:1)
  secondary: KkfcColors.ink2, // --k-ink-2 (#43536A)
  onSecondary: KkfcColors.surface, // white (#FFFFFF)
  secondaryContainer: KkfcColors.selectedTint, // --k-selected-tint (#E7ECF4)
  onSecondaryContainer: KkfcColors.ink, // --k-ink (#19293E)
  tertiary: KkfcColors.ink2, // --k-ink-2 (#43536A)
  onTertiary: KkfcColors.surface, // white (#FFFFFF)
  error: KkfcColors.danger, // --k-danger (#B3261E)
  onError: KkfcColors.onSolid, // --k-on-solid (#FFFFFF, 5.21:1)
  errorContainer: KkfcColors.dangerBg, // --k-danger-bg (#FCEBEA)
  onErrorContainer: KkfcColors.danger, // --k-danger (#B3261E)
  surface: KkfcColors.canvas, // --k-canvas (#F7F3EC)
  onSurface: KkfcColors.ink, // --k-ink (#19293E)
  onSurfaceVariant: KkfcColors.ink2, // --k-ink-2 (#43536A)
  surfaceContainerLowest: KkfcColors.surface, // --k-surface (#FFFFFF)
  surfaceContainerLow: KkfcColors.surfaceSubtle, // --k-surface-subtle (#FBF9F5)
  surfaceContainer: KkfcColors.surface, // --k-surface (#FFFFFF)
  surfaceContainerHigh: KkfcColors.surfaceSubtle, // --k-surface-subtle (#FBF9F5)
  surfaceContainerHighest: KkfcColors.canvasSunken, // --k-canvas-sunken (#EEE8DC)
  outline: KkfcColors.borderStrong, // --k-border-strong (#76849A)
  outlineVariant: KkfcColors.border, // --k-border (#DDD6C9)
  inverseSurface: KkfcColors.shell, // --k-shell (#19293E)
  onInverseSurface: KkfcColors.surface, // white (#FFFFFF)
  surfaceTint: Colors.transparent,
);

const ColorScheme kkfcKitchenScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFE3E7EF), // ink.100
  onPrimary: Color(0xFF0B111D), // ink.950
  secondary: KkfcColors.borderStrong, // --k-border-strong (#76849A)
  onSecondary: Color(0xFF0B111D), // ink.950
  secondaryContainer: KkfcColors.shell, // --k-shell (#19293E)
  onSecondaryContainer: KkfcColors.canvas, // --k-canvas (#F7F3EC)
  tertiary: KkfcColors.borderStrong, // --k-border-strong (#76849A)
  onTertiary: Color(0xFF0B111D), // ink.950
  error: KkfcColors.dangerBorder, // --k-danger-border (#EDB3AF)
  onError: Color(0xFF3D0C06), // red.950
  errorContainer: Color(0xFF3D0C06), // red.950
  onErrorContainer: KkfcColors.dangerBorder, // --k-danger-border (#EDB3AF)
  surface: Color(0xFF0B111D), // ink.950
  onSurface: KkfcColors.canvas, // --k-canvas (#F7F3EC)
  onSurfaceVariant: KkfcColors.borderStrong, // --k-border-strong (#76849A)
  surfaceContainerLowest: Color(0xFF141D2E), // ink.900
  surfaceContainerLow: Color(0xFF141D2E), // ink.900
  surfaceContainer: Color(0xFF141D2E), // ink.900
  surfaceContainerHigh: Color(0xFF141D2E), // ink.900
  surfaceContainerHighest: KkfcColors.shellRaised, // --k-shell-raised (#293F58)
  outline: KkfcColors.borderStrong, // --k-border-strong (#76849A)
  outlineVariant: KkfcColors.shellRaised, // --k-shell-raised (#293F58)
  inverseSurface: Color(0xFFE3E7EF), // ink.100
  onInverseSurface: Color(0xFF0B111D), // ink.950
  surfaceTint: Colors.transparent,
);
