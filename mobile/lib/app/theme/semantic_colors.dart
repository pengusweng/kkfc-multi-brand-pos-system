import 'package:flutter/material.dart';

import 'color_tokens.dart';

@immutable
class KkfcTone {
  const KkfcTone({required this.bg, required this.fg, this.border});

  final Color bg;
  final Color fg;
  final Color? border;

  static KkfcTone lerp(KkfcTone a, KkfcTone b, double t) => KkfcTone(
    bg: Color.lerp(a.bg, b.bg, t)!,
    fg: Color.lerp(a.fg, b.fg, t)!,
    border: Color.lerp(a.border, b.border, t),
  );
}

@immutable
class KkfcSemanticColors extends ThemeExtension<KkfcSemanticColors> {
  const KkfcSemanticColors({
    required this.bgCanvas,
    required this.bgSurface,
    required this.bgRaised,
    required this.bgSunken,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.textInverse,
    required this.borderDefault,
    required this.borderStrong,
    required this.borderFocus,
    required this.borderFocusInverse,
    required this.highlights,
    required this.highlightsSecondary,
    required this.tag,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.review,
    required this.actionInfo,
    required this.actionReview,
    required this.actionSuccess,
    required this.ageNormal,
    required this.ageCaution,
    required this.ageLate,
    this.action = KkfcColors.action,
    this.actionHover = KkfcColors.actionHover,
    this.actionPressed = KkfcColors.actionPressed,
    this.actionInk = KkfcColors.actionInk,
    this.actionTint = KkfcColors.actionTint,
    this.identity = KkfcColors.identity,
    this.shell = KkfcColors.shell,
    this.shellRaised = KkfcColors.shellRaised,
    this.selected = KkfcColors.selected,
    this.selectedTint = KkfcColors.selectedTint,
    this.onSelected = KkfcColors.onSelected,
    this.onSolid = KkfcColors.onSolid,
    this.onShellSelected = KkfcColors.onShellSelected,
    this.shellSelected = KkfcColors.shellSelected,
    this.onAccent = KkfcColors.onAccent,
    this.onWarningSolid = KkfcColors.onWarningSolid,
  });

  final Color bgCanvas;
  final Color bgSurface;
  final Color bgRaised;
  final Color bgSunken;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color textInverse;
  final Color borderDefault;
  final Color borderStrong;
  final Color borderFocus;
  final Color borderFocusInverse;
  final Color highlights;
  final Color highlightsSecondary;
  final KkfcTone tag;
  final KkfcTone success;
  final KkfcTone warning;
  final KkfcTone danger;
  final KkfcTone info;
  final KkfcTone review;
  final KkfcTone actionInfo;
  final KkfcTone actionReview;
  final KkfcTone actionSuccess;
  final KkfcTone ageNormal;
  final KkfcTone ageCaution;
  final KkfcTone ageLate;

  // Copper & Navy tokens
  final Color action;
  final Color actionHover;
  final Color actionPressed;
  final Color actionInk;
  final Color actionTint;
  final Color identity;
  final Color shell;
  final Color shellRaised;
  final Color selected;
  final Color selectedTint;

  // Contrast pair tokens (WCAG 2.2 AA)
  final Color onSelected;
  final Color onSolid;
  final Color onShellSelected;
  final Color shellSelected;
  final Color onAccent;
  final Color onWarningSolid;

  // Light (counter), matching the Colour Language spec
  static const light = KkfcSemanticColors(
    bgCanvas: KkfcColors.canvas, // --k-canvas (#F7F3EC)
    bgSurface: KkfcColors.surface, // --k-surface (#FFFFFF)
    bgRaised: KkfcColors.surface, // --k-surface (#FFFFFF)
    bgSunken: KkfcColors.canvasSunken, // --k-canvas-sunken (#EEE8DC)
    textPrimary: KkfcColors.ink, // --k-ink (#19293E)
    textSecondary: KkfcColors.ink2, // --k-ink-2 (#43536A)
    textDisabled: KkfcColors.ink3, // --k-ink-3 (#586579)
    textInverse: KkfcColors.surface, // white (#FFFFFF)
    borderDefault: KkfcColors.border, // --k-border (#DDD6C9)
    borderStrong: KkfcColors.borderStrong, // --k-border-strong (#76849A)
    borderFocus: KkfcColors.focus, // --k-focus (#1F66C9)
    borderFocusInverse: KkfcColors.focusOnShell, // --k-focus-on-shell (#FFC18E)
    highlights: KkfcColors.accent, // --k-accent (#FF9248)
    highlightsSecondary: KkfcColors.actionTint, // --k-action-tint (#F9EBE2)
    tag: KkfcTone(
      bg: KkfcColors.neutralBg, // --k-neutral-bg (#EDF0F4)
      fg: KkfcColors.neutral, // --k-neutral (#46566C)
      border: KkfcColors.neutralBorder, // --k-neutral-border (#D3DDE2)
    ),
    success: KkfcTone(
      bg: KkfcColors.successBg, // --k-success-bg (#E3F4E9)
      fg: KkfcColors.success, // --k-success (#166B3A)
      border: KkfcColors.successBorder, // --k-success-border (#9ED2B0)
    ),
    warning: KkfcTone(
      bg: KkfcColors.warningBg, // --k-warning-bg (#FCF3CF)
      fg: KkfcColors.warning, // --k-warning (#6A5200)
      border: KkfcColors.warningBorder, // --k-warning-border (#DDBE55)
    ),
    danger: KkfcTone(
      bg: KkfcColors.dangerBg, // --k-danger-bg (#FCEBEA)
      fg: KkfcColors.danger, // --k-danger (#B3261E)
      border: KkfcColors.dangerBorder, // --k-danger-border (#EDB3AF)
    ),
    info: KkfcTone(
      bg: KkfcColors.infoBg, // --k-info-bg (#E6F0FA)
      fg: KkfcColors.info, // --k-info (#1B5A96)
      border: KkfcColors.infoBorder, // --k-info-border (#A5C6E8)
    ),
    review: KkfcTone(
      bg: KkfcColors.reviewBg, // --k-review-bg (#F0ECFB)
      fg: KkfcColors.review, // --k-review (#5A3EA6)
      border: KkfcColors.reviewBorder, // --k-review-border (#C8BBEC)
    ),
    actionInfo: KkfcTone(
      bg: KkfcColors.infoSolid, // --k-info-solid (#1F67AB)
      fg: KkfcColors.onSolid, // --k-on-solid (#FFFFFF)
    ),
    actionReview: KkfcTone(
      bg: KkfcColors.reviewSolid, // --k-review-solid (#6346B5)
      fg: KkfcColors.onSolid, // --k-on-solid (#FFFFFF)
    ),
    actionSuccess: KkfcTone(
      bg: KkfcColors.successSolid, // --k-success-solid (#187A42)
      fg: KkfcColors.onSolid, // --k-on-solid (#FFFFFF)
    ),
    ageNormal: KkfcTone(
      bg: KkfcColors.neutralBg, // --k-neutral-bg (#EDF0F4)
      fg: KkfcColors.ink, // --k-ink (#19293E)
    ),
    ageCaution: KkfcTone(
      bg: KkfcColors.warningSolid, // --k-warning-solid (#EDBE3D)
      fg: KkfcColors.onWarningSolid, // --k-on-warning-solid (#19293E)
    ),
    ageLate: KkfcTone(
      bg: KkfcColors.dangerSolid, // --k-danger-solid (#B3261E)
      fg: KkfcColors.onSolid, // --k-on-solid (#FFFFFF)
    ),
    action: KkfcColors.action, // --k-action (#A8562A)
    actionHover: KkfcColors.actionHover, // --k-action-hover (#8E4722)
    actionPressed: KkfcColors.actionPressed, // --k-action-pressed (#743A1B)
    actionInk: KkfcColors.actionInk, // --k-action-ink (#8E4722)
    actionTint: KkfcColors.actionTint, // --k-action-tint (#F9EBE2)
    identity: KkfcColors.identity, // --k-identity (#B86843)
    shell: KkfcColors.shell, // --k-shell (#19293E)
    shellRaised: KkfcColors.shellRaised, // --k-shell-raised (#293F58)
    selected: KkfcColors.selected, // --k-selected (#1D2940)
    selectedTint: KkfcColors.selectedTint, // --k-selected-tint (#E7ECF4)
    onSelected: KkfcColors.onSelected, // --k-on-selected (#FFFFFF)
    onSolid: KkfcColors.onSolid, // --k-on-solid (#FFFFFF)
    onShellSelected: KkfcColors.onShellSelected, // --k-on-shell-selected (#19293E)
    shellSelected: KkfcColors.shellSelected, // --k-shell-selected (#F7F3EC)
    onAccent: KkfcColors.onAccent, // --k-on-accent (#19293E)
    onWarningSolid: KkfcColors.onWarningSolid, // --k-on-warning-solid (#19293E)
  );

  // Dark (kitchen), from theme/dark
  static const dark = KkfcSemanticColors(
    bgCanvas: Color(0xFF0B111D), // ink.950
    bgSurface: Color(0xFF141D2E), // ink.900
    bgRaised: Color(0xFF1D2940), // ink.800
    bgSunken: Color(0xFF0B111D), // ink.950
    textPrimary: Color(0xFFF2F4F8), // ink.50
    textSecondary: Color(0xFF9CA9C0), // ink.300
    textDisabled: Color(0xFF4C5D7D), // ink.500
    textInverse: Color(0xFF0B111D), // ink.950
    borderDefault: Color(0xFF283650), // ink.700
    borderStrong: KkfcColors.borderStrong, // --k-border-strong (#76849A)
    borderFocus: KkfcColors.focus, // --k-focus (#1F66C9)
    borderFocusInverse: KkfcColors.focusOnShell, // --k-focus-on-shell (#FFC18E)
    highlights: KkfcColors.accent, // --k-accent (#FF9248)
    highlightsSecondary: KkfcColors.actionTint, // --k-action-tint (#F9EBE2)
    tag: KkfcTone(
      bg: Color(0xFF1D2940),
      fg: Color(0xFFE3E7EF),
      border: Color(0xFF374763),
    ), // ink.800 / ink.100
    success: KkfcTone(
      bg: Color(0xFF052A24),
      fg: KkfcColors.successBorder,
      border: KkfcColors.successSolid,
    ),
    warning: KkfcTone(
      bg: Color(0xFF332300),
      fg: KkfcColors.warningSolid,
      border: KkfcColors.warning,
    ),
    danger: KkfcTone(
      bg: Color(0xFF3D0C06),
      fg: KkfcColors.dangerBorder,
      border: KkfcColors.dangerSolid,
    ),
    info: KkfcTone(
      bg: Color(0xFF0C1D3F),
      fg: KkfcColors.infoBorder,
      border: KkfcColors.info,
    ),
    review: KkfcTone(
      bg: Color(0xFF330D2C),
      fg: KkfcColors.reviewBorder,
      border: KkfcColors.review,
    ),
    actionInfo: KkfcTone(
      bg: KkfcColors.infoSolid,
      fg: KkfcColors.onSolid,
    ),
    actionReview: KkfcTone(
      bg: KkfcColors.reviewSolid,
      fg: KkfcColors.onSolid,
    ),
    actionSuccess: KkfcTone(
      bg: KkfcColors.successSolid,
      fg: KkfcColors.onSolid,
    ),
    ageNormal: KkfcTone(
      bg: Color(0xFF1D2940),
      fg: Color(0xFFF2F4F8),
    ),
    ageCaution: KkfcTone(
      bg: KkfcColors.warningSolid,
      fg: KkfcColors.onWarningSolid,
    ),
    ageLate: KkfcTone(
      bg: KkfcColors.dangerSolid,
      fg: KkfcColors.onSolid,
    ),
    action: KkfcColors.action,
    actionHover: KkfcColors.actionHover,
    actionPressed: KkfcColors.actionPressed,
    actionInk: KkfcColors.actionInk,
    actionTint: KkfcColors.actionTint,
    identity: KkfcColors.identity,
    shell: KkfcColors.shell,
    shellRaised: KkfcColors.shellRaised,
    selected: KkfcColors.selected,
    selectedTint: KkfcColors.selectedTint,
    onSelected: KkfcColors.onSelected,
    onSolid: KkfcColors.onSolid,
    onShellSelected: KkfcColors.onShellSelected,
    shellSelected: KkfcColors.shellSelected,
    onAccent: KkfcColors.onAccent,
    onWarningSolid: KkfcColors.onWarningSolid,
  );

  @override
  KkfcSemanticColors copyWith({
    Color? bgCanvas,
    Color? bgSurface,
    Color? bgRaised,
    Color? bgSunken,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? textInverse,
    Color? borderDefault,
    Color? borderStrong,
    Color? borderFocus,
    Color? borderFocusInverse,
    Color? highlights,
    Color? highlightsSecondary,
    KkfcTone? tag,
    KkfcTone? success,
    KkfcTone? warning,
    KkfcTone? danger,
    KkfcTone? info,
    KkfcTone? review,
    KkfcTone? actionInfo,
    KkfcTone? actionReview,
    KkfcTone? actionSuccess,
    KkfcTone? ageNormal,
    KkfcTone? ageCaution,
    KkfcTone? ageLate,
    Color? action,
    Color? actionHover,
    Color? actionPressed,
    Color? actionInk,
    Color? actionTint,
    Color? identity,
    Color? shell,
    Color? shellRaised,
    Color? selected,
    Color? selectedTint,
    Color? onSelected,
    Color? onSolid,
    Color? onShellSelected,
    Color? shellSelected,
    Color? onAccent,
    Color? onWarningSolid,
  }) {
    return KkfcSemanticColors(
      bgCanvas: bgCanvas ?? this.bgCanvas,
      bgSurface: bgSurface ?? this.bgSurface,
      bgRaised: bgRaised ?? this.bgRaised,
      bgSunken: bgSunken ?? this.bgSunken,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      textInverse: textInverse ?? this.textInverse,
      borderDefault: borderDefault ?? this.borderDefault,
      borderStrong: borderStrong ?? this.borderStrong,
      borderFocus: borderFocus ?? this.borderFocus,
      borderFocusInverse: borderFocusInverse ?? this.borderFocusInverse,
      highlights: highlights ?? this.highlights,
      highlightsSecondary: highlightsSecondary ?? this.highlightsSecondary,
      tag: tag ?? this.tag,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      review: review ?? this.review,
      actionInfo: actionInfo ?? this.actionInfo,
      actionReview: actionReview ?? this.actionReview,
      actionSuccess: actionSuccess ?? this.actionSuccess,
      ageNormal: ageNormal ?? this.ageNormal,
      ageCaution: ageCaution ?? this.ageCaution,
      ageLate: ageLate ?? this.ageLate,
      action: action ?? this.action,
      actionHover: actionHover ?? this.actionHover,
      actionPressed: actionPressed ?? this.actionPressed,
      actionInk: actionInk ?? this.actionInk,
      actionTint: actionTint ?? this.actionTint,
      identity: identity ?? this.identity,
      shell: shell ?? this.shell,
      shellRaised: shellRaised ?? this.shellRaised,
      selected: selected ?? this.selected,
      selectedTint: selectedTint ?? this.selectedTint,
      onSelected: onSelected ?? this.onSelected,
      onSolid: onSolid ?? this.onSolid,
      onShellSelected: onShellSelected ?? this.onShellSelected,
      shellSelected: shellSelected ?? this.shellSelected,
      onAccent: onAccent ?? this.onAccent,
      onWarningSolid: onWarningSolid ?? this.onWarningSolid,
    );
  }

  @override
  KkfcSemanticColors lerp(ThemeExtension<KkfcSemanticColors>? other, double t) {
    if (other is! KkfcSemanticColors) return this;
    return KkfcSemanticColors(
      bgCanvas: Color.lerp(bgCanvas, other.bgCanvas, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      bgRaised: Color.lerp(bgRaised, other.bgRaised, t)!,
      bgSunken: Color.lerp(bgSunken, other.bgSunken, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      borderFocusInverse: Color.lerp(
        borderFocusInverse,
        other.borderFocusInverse,
        t,
      )!,
      highlights: Color.lerp(highlights, other.highlights, t)!,
      highlightsSecondary: Color.lerp(
        highlightsSecondary,
        other.highlightsSecondary,
        t,
      )!,
      tag: KkfcTone.lerp(tag, other.tag, t),
      success: KkfcTone.lerp(success, other.success, t),
      warning: KkfcTone.lerp(warning, other.warning, t),
      danger: KkfcTone.lerp(danger, other.danger, t),
      info: KkfcTone.lerp(info, other.info, t),
      review: KkfcTone.lerp(review, other.review, t),
      actionInfo: KkfcTone.lerp(actionInfo, other.actionInfo, t),
      actionReview: KkfcTone.lerp(actionReview, other.actionReview, t),
      actionSuccess: KkfcTone.lerp(actionSuccess, other.actionSuccess, t),
      ageNormal: KkfcTone.lerp(ageNormal, other.ageNormal, t),
      ageCaution: KkfcTone.lerp(ageCaution, other.ageCaution, t),
      ageLate: KkfcTone.lerp(ageLate, other.ageLate, t),
      action: Color.lerp(action, other.action, t)!,
      actionHover: Color.lerp(actionHover, other.actionHover, t)!,
      actionPressed: Color.lerp(actionPressed, other.actionPressed, t)!,
      actionInk: Color.lerp(actionInk, other.actionInk, t)!,
      actionTint: Color.lerp(actionTint, other.actionTint, t)!,
      identity: Color.lerp(identity, other.identity, t)!,
      shell: Color.lerp(shell, other.shell, t)!,
      shellRaised: Color.lerp(shellRaised, other.shellRaised, t)!,
      selected: Color.lerp(selected, other.selected, t)!,
      selectedTint: Color.lerp(selectedTint, other.selectedTint, t)!,
      onSelected: Color.lerp(onSelected, other.onSelected, t)!,
      onSolid: Color.lerp(onSolid, other.onSolid, t)!,
      onShellSelected: Color.lerp(onShellSelected, other.onShellSelected, t)!,
      shellSelected: Color.lerp(shellSelected, other.shellSelected, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      onWarningSolid: Color.lerp(onWarningSolid, other.onWarningSolid, t)!,
    );
  }
}
