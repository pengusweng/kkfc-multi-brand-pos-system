import 'package:flutter/material.dart';

/// Design tokens matching the "Colour language" specification.
///
/// Every swatch is a bound variable corresponding to the design system CSS names:
/// - Warm sand: ground (where work sits; never carries meaning)
/// - Navy: structure and "you are here" (shell, ink, and anything selected)
/// - Copper: "do this next" (actions only; never selection, never status)
/// - Orange: attention on navy (only on the shell: sidebar counts)
/// - Slate: waiting or inactive (queued, draft, not recorded, inactive)
/// - Blue: in progress or FYI (preparing, information)
/// - Violet: waiting on a check (QC check, submitted for review, pending approval)
/// - Green: done and fine (ready, accepted, active, success)
/// - Gold: look at this, not blocking (setup pending, variance, kitchen notes)
/// - Red: blocked, failed, late (late from 15:00, denied, failed, destructive)
///
/// Contrast pairs meet WCAG 2.2 AA (enforced by color system specs).
abstract final class KkfcColors {
  // --- Warm sand: ground ---
  /// `--k-canvas`: Canvas ground where work sits (#F7F3EC)
  static const Color canvas = Color(0xFFF7F3EC);

  /// `--k-canvas-sunken`: Sunken ground (#EEE8DC)
  static const Color canvasSunken = Color(0xFFEEE8DC);

  /// `--k-surface`: Default surface (#FFFFFF)
  static const Color surface = Color(0xFFFFFFFF);

  /// `--k-surface-subtle`: Subtle surface (#FBF9F5)
  static const Color surfaceSubtle = Color(0xFFFBF9F5);

  /// `--k-border`: Default border (#DDD6C9)
  static const Color border = Color(0xFFDDD6C9);

  /// `--k-divider`: Divider line (#EDE8DF)
  static const Color divider = Color(0xFFEDE8DF);

  /// `--k-border-strong`: Control boundary with 3:1 contrast ratio (#76849A)
  static const Color borderStrong = Color(0xFF76849A);

  // --- Navy: structure and "you are here" ---
  /// `--k-shell`: Main shell background (#19293E)
  static const Color shell = Color(0xFF19293E);

  /// `--k-shell-raised`: Raised shell surface (#293F58)
  static const Color shellRaised = Color(0xFF293F58);

  /// `--k-selected`: Selected state (chips, tabs, segmented options, bottom nav) (#1D2940)
  static const Color selected = Color(0xFF1D2940);

  /// `--k-selected-tint`: Tinted surface for selected items (#E7ECF4)
  static const Color selectedTint = Color(0xFFE7ECF4);

  /// `--k-ink`: Primary text / typography ink (#19293E)
  static const Color ink = Color(0xFF19293E);

  /// `--k-ink-2`: Secondary text ink (#43536A)
  static const Color ink2 = Color(0xFF43536A);

  /// `--k-ink-3`: Minimum contrast text ink / muted (#586579)
  static const Color ink3 = Color(0xFF586579);

  // --- Copper: "do this next" ---
  /// `--k-action`: Primary action button / element (#A8562A)
  static const Color action = Color(0xFFA8562A);

  /// `--k-action-hover`: Action hover state (#8E4722)
  static const Color actionHover = Color(0xFF8E4722);

  /// `--k-action-pressed`: Action pressed state (#743A1B)
  static const Color actionPressed = Color(0xFF743A1B);

  /// `--k-action-ink`: Copper text (#8E4722)
  static const Color actionInk = Color(0xFF8E4722);

  /// `--k-action-tint`: Action tinted background (#F9EBE2)
  static const Color actionTint = Color(0xFFF9EBE2);

  /// `--k-identity`: Brand identity non-text (#B86843)
  static const Color identity = Color(0xFFB86843);

  // --- Orange: attention on navy ---
  /// `--k-accent`: Sidebar counts / attention on navy (#FF9248)
  static const Color accent = Color(0xFFFF9248);

  /// `--k-focus-on-shell`: Focus ring when placed on navy shell (#FFC18E)
  static const Color focusOnShell = Color(0xFFFFC18E);

  // --- Slate: waiting or inactive ---
  /// `--k-neutral`: Slate ink for queued, draft, inactive (#46566C)
  static const Color neutral = Color(0xFF46566C);

  /// `--k-neutral-bg`: Slate tinted background (#EDF0F4)
  static const Color neutralBg = Color(0xFFEDF0F4);

  /// `--k-neutral-border`: Slate border (#D3DDE2)
  static const Color neutralBorder = Color(0xFFD3DDE2);

  /// `--k-neutral-solid`: Slate solid fill (#586579)
  static const Color neutralSolid = Color(0xFF586579);

  // --- Blue: in progress or FYI ---
  /// `--k-info`: Blue ink for preparing, information (#1B5A96)
  static const Color info = Color(0xFF1B5A96);

  /// `--k-info-bg`: Blue tinted background (#E6F0FA)
  static const Color infoBg = Color(0xFFE6F0FA);

  /// `--k-info-border`: Blue border (#A5C6E8)
  static const Color infoBorder = Color(0xFFA5C6E8);

  /// `--k-info-solid`: Blue solid fill (#1F67AB)
  static const Color infoSolid = Color(0xFF1F67AB);

  /// `--k-focus`: Primary focus ring (#1F66C9)
  static const Color focus = Color(0xFF1F66C9);

  // --- Violet: waiting on a check ---
  /// `--k-review`: Violet ink for QC check, review, approval (#5A3EA6)
  static const Color review = Color(0xFF5A3EA6);

  /// `--k-review-bg`: Violet tinted background (#F0ECFB)
  static const Color reviewBg = Color(0xFFF0ECFB);

  /// `--k-review-border`: Violet border (#C8BBEC)
  static const Color reviewBorder = Color(0xFFC8BBEC);

  /// `--k-review-solid`: Violet solid fill (#6346B5)
  static const Color reviewSolid = Color(0xFF6346B5);

  // --- Green: done and fine ---
  /// `--k-success`: Green ink for ready, accepted, active, success (#166B3A)
  static const Color success = Color(0xFF166B3A);

  /// `--k-success-bg`: Green tinted background (#E3F4E9)
  static const Color successBg = Color(0xFFE3F4E9);

  /// `--k-success-border`: Green border (#9ED2B0)
  static const Color successBorder = Color(0xFF9ED2B0);

  /// `--k-success-solid`: Green solid fill (#187A42)
  static const Color successSolid = Color(0xFF187A42);

  // --- Gold: look at this, not blocking ---
  /// `--k-warning`: Gold ink for setup pending, notes (#6A5200)
  static const Color warning = Color(0xFF6A5200);

  /// `--k-warning-bg`: Gold tinted background (#FCF3CF)
  static const Color warningBg = Color(0xFFFCF3CF);

  /// `--k-warning-border`: Gold border (#DDBE55)
  static const Color warningBorder = Color(0xFFDDBE55);

  /// `--k-warning-solid`: Gold solid fill (#EDBE3D)
  static const Color warningSolid = Color(0xFFEDBE3D);

  // --- Red: blocked, failed, late ---
  /// `--k-danger`: Red ink for late, denied, failed (#B3261E)
  static const Color danger = Color(0xFFB3261E);

  /// `--k-danger-bg`: Red tinted background (#FCEBEA)
  static const Color dangerBg = Color(0xFFFCEBEA);

  /// `--k-danger-border`: Red border (#EDB3AF)
  static const Color dangerBorder = Color(0xFFEDB3AF);

  /// `--k-danger-solid`: Red solid fill (#B3261E)
  static const Color dangerSolid = Color(0xFFB3261E);

  // --- Contrast pair foreground variables (WCAG 2.2 AA) ---
  /// `--k-on-selected`: Foreground text on selected Navy (#FFFFFF, 14.55:1)
  static const Color onSelected = Color(0xFFFFFFFF);

  /// `--k-on-solid`: Foreground text on Action / Solid fills (#FFFFFF, 5.21:1)
  static const Color onSolid = Color(0xFFFFFFFF);

  /// `--k-on-shell-selected`: Foreground text on shell-selected (#19293E, 13.30:1)
  static const Color onShellSelected = Color(0xFF19293E);

  /// `--k-shell-selected`: Background for selected shell element (#F7F3EC, 13.30:1)
  static const Color shellSelected = Color(0xFFF7F3EC);

  /// `--k-on-accent`: Foreground text on orange Accent (#19293E, 6.62:1)
  static const Color onAccent = Color(0xFF19293E);

  /// `--k-on-warning-solid`: Foreground text on Gold warning-solid (#19293E, 8.43:1)
  static const Color onWarningSolid = Color(0xFF19293E);

  // --- AppHeader & Shell tokens ---
  /// Muted wordmark text on navy shell (#8C9BAE)
  static const Color shellMutedText = Color(0xFF8C9BAE);

  /// Role badge fill on navy shell (#24364D)
  static const Color shellRoleBg = Color(0xFF24364D);

  /// Role badge border on navy shell (#384B66)
  static const Color shellRoleBorder = Color(0xFF384B66);

  // --- Kitchen Ticket Card tokens ---
  /// Deep navy ink for ticket header, quantity, and item titles (#102A43)
  static const Color ticketInk = Color(0xFF102A43);

  /// Card border and progress bar track (#E2E8F0)
  static const Color ticketBorder = Color(0xFFE2E8F0);

  /// Subtle resting card shadow (#06000000)
  static const Color ticketShadow = Color(0x06000000);

  /// Muted slate for modifiers, payment label, and brand badge border (#64748B)
  static const Color ticketMuted = Color(0xFF64748B);

  /// Secondary slate for Details link and timer tick marks (#334155)
  static const Color ticketSubtleInk = Color(0xFF334155);

  /// Medium slate for brand display name (#475569)
  static const Color ticketBrandName = Color(0xFF475569);

  /// Disabled primary button fill on ticket card (#CBD5E1)
  static const Color ticketDisabledBg = Color(0xFFCBD5E1);

  /// Progress bar fill when ticket is on time (#506176)
  static const Color ticketAgeOnTime = Color(0xFF506176);

  /// Progress bar fill when ticket is due soon (#D97706)
  static const Color ticketAgeDueSoon = Color(0xFFD97706);

  /// Progress bar fill when ticket is late (#DC2626)
  static const Color ticketAgeLate = Color(0xFFDC2626);

  /// Kitchen item note callout background (#FEF3C7)
  static const Color ticketNoteBg = Color(0xFFFEF3C7);

  /// Kitchen item note callout border (#FDE68A)
  static const Color ticketNoteBorder = Color(0xFFFDE68A);

  /// QC item Pass button fill when active (#187A42)
  static const Color qcPassBg = successSolid;

  /// QC Fail button border / text (#B3261E)
  static const Color qcFailBorder = danger;

  // --- Kitchen Ticket Status color tokens ---

  // Acknowledged: darker shade of blue
  /// Background for acknowledged status badge/tint (#D8E6F5)
  static const Color statusAcknowledgedBg = Color(0xFFD8E6F5);

  /// Border for acknowledged status badge (#8EB5E0)
  static const Color statusAcknowledgedBorder = Color(0xFF8EB5E0);

  /// Foreground ink / text for acknowledged status (darker blue, #0D3B66)
  static const Color statusAcknowledgedFg = Color(0xFF0D3B66);

  /// Solid / accent color for acknowledged ticket (#104477)
  static const Color statusAcknowledgedSolid = Color(0xFF104477);

  /// Card border for acknowledged status (#8EB5E0)
  static const Color statusAcknowledgedCardBorder = Color(0xFF8EB5E0);

  // Preparing: lighter shade of blue
  /// Background for preparing status badge/tint (#EDF7FF)
  static const Color statusPreparingBg = Color(0xFFEDF7FF);

  /// Border for preparing status badge (#BAE6FD)
  static const Color statusPreparingBorder = Color(0xFFBAE6FD);

  /// Foreground ink / text for preparing status (lighter blue, #0369A1)
  static const Color statusPreparingFg = Color(0xFF0369A1);

  /// Solid / accent color for preparing ticket (#0284C7)
  static const Color statusPreparingSolid = Color(0xFF0284C7);

  /// Card border for preparing status (#BAE6FD)
  static const Color statusPreparingCardBorder = Color(0xFFBAE6FD);

  // Rework: copper / amber status
  /// Background for rework badge/box (#FBF6EF)
  static const Color reworkBg = Color(0xFFFBF6EF);

  /// Border for rework badge/box (#DCBFA9)
  static const Color reworkBorder = Color(0xFFDCBFA9);

  /// Foreground ink / text for rework (#8A4621)
  static const Color reworkText = Color(0xFF8A4621);

  /// Solid / accent fill for rework (#8A4621)
  static const Color reworkSolid = Color(0xFF8A4621);

  /// Card border for rework status (#DCBFA9)
  static const Color reworkCardBorder = Color(0xFFDCBFA9);

  // Queued: slate status
  static const Color statusQueuedBg = neutralBg;
  static const Color statusQueuedBorder = neutralBorder;
  static const Color statusQueuedFg = neutral;
  static const Color statusQueuedSolid = neutralSolid;
  static const Color statusQueuedCardBorder = ticketBorder;

  // Checking (QC Check): violet status
  static const Color statusCheckingBg = reviewBg;
  static const Color statusCheckingBorder = reviewBorder;
  static const Color statusCheckingFg = review;
  static const Color statusCheckingSolid = reviewSolid;
  static const Color statusCheckingCardBorder = reviewBorder;

  // Ready: green status
  static const Color statusReadyBg = successBg;
  static const Color statusReadyBorder = successBorder;
  static const Color statusReadyFg = success;
  static const Color statusReadySolid = successSolid;
  static const Color statusReadyCardBorder = successBorder;

  // --- Availability tokens ---
  /// Status text color for unavailable menu item on availability cards (#8C3A27)
  static const Color availabilityUnavailableText = Color(0xFF8C3A27);

  /// Warning badge fill on availability confirmation dialog (#FEF3C7)
  static const Color availabilityWarningBg = Color(0xFFFEF3C7);

  /// Warning badge icon color on availability confirmation dialog (#8A6D1C)
  static const Color availabilityWarningIcon = Color(0xFF8A6D1C);

  /// Subtle gold card border on availability confirmation dialog (#EAC775)
  static const Color availabilityCardBorder = Color(0xFFEAC775);
}

/// Representation of a verified WCAG 2.2 AA contrast pair.
@immutable
class KkfcContrastPair {
  const KkfcContrastPair({
    required this.name,
    required this.foreground,
    required this.background,
    required this.contrastRatio,
  });

  /// The pair identifier from the specification, e.g. "ink on canvas".
  final String name;

  /// Foreground (text/icon) color.
  final Color foreground;

  /// Background color.
  final Color background;

  /// Contrast ratio according to WCAG 2.2 AA.
  final double contrastRatio;
}

/// The 15 verified WCAG 2.2 AA contrast pairs from the design specification.
abstract final class KkfcContrastPairs {
  /// ink on canvas (13.30:1)
  static const KkfcContrastPair inkOnCanvas = KkfcContrastPair(
    name: 'ink on canvas',
    foreground: KkfcColors.ink,
    background: KkfcColors.canvas,
    contrastRatio: 13.30,
  );

  /// ink-2 on canvas (7.07:1)
  static const KkfcContrastPair ink2OnCanvas = KkfcContrastPair(
    name: 'ink-2 on canvas',
    foreground: KkfcColors.ink2,
    background: KkfcColors.canvas,
    contrastRatio: 7.07,
  );

  /// ink-3 on canvas (5.34:1)
  static const KkfcContrastPair ink3OnCanvas = KkfcContrastPair(
    name: 'ink-3 on canvas',
    foreground: KkfcColors.ink3,
    background: KkfcColors.canvas,
    contrastRatio: 5.34,
  );

  /// on-selected on selected (14.55:1)
  static const KkfcContrastPair onSelectedOnSelected = KkfcContrastPair(
    name: 'on-selected on selected',
    foreground: KkfcColors.onSelected,
    background: KkfcColors.selected,
    contrastRatio: 14.55,
  );

  /// on-solid on action (5.21:1)
  static const KkfcContrastPair onSolidOnAction = KkfcContrastPair(
    name: 'on-solid on action',
    foreground: KkfcColors.onSolid,
    background: KkfcColors.action,
    contrastRatio: 5.21,
  );

  /// action-ink on surface (6.83:1)
  static const KkfcContrastPair actionInkOnSurface = KkfcContrastPair(
    name: 'action-ink on surface',
    foreground: KkfcColors.actionInk,
    background: KkfcColors.surface,
    contrastRatio: 6.83,
  );

  /// on-shell-selected on shell-selected (13.30:1)
  static const KkfcContrastPair onShellSelectedOnShellSelected =
      KkfcContrastPair(
        name: 'on-shell-selected on shell-selected',
        foreground: KkfcColors.onShellSelected,
        background: KkfcColors.shellSelected,
        contrastRatio: 13.30,
      );

  /// on-accent on accent (6.62:1)
  static const KkfcContrastPair onAccentOnAccent = KkfcContrastPair(
    name: 'on-accent on accent',
    foreground: KkfcColors.onAccent,
    background: KkfcColors.accent,
    contrastRatio: 6.62,
  );

  /// neutral on neutral-bg (6.54:1)
  static const KkfcContrastPair neutralOnNeutralBg = KkfcContrastPair(
    name: 'neutral on neutral-bg',
    foreground: KkfcColors.neutral,
    background: KkfcColors.neutralBg,
    contrastRatio: 6.54,
  );

  /// info on info-bg (6.17:1)
  static const KkfcContrastPair infoOnInfoBg = KkfcContrastPair(
    name: 'info on info-bg',
    foreground: KkfcColors.info,
    background: KkfcColors.infoBg,
    contrastRatio: 6.17,
  );

  /// review on review-bg (6.77:1)
  static const KkfcContrastPair reviewOnReviewBg = KkfcContrastPair(
    name: 'review on review-bg',
    foreground: KkfcColors.review,
    background: KkfcColors.reviewBg,
    contrastRatio: 6.77,
  );

  /// success on success-bg (5.75:1)
  static const KkfcContrastPair successOnSuccessBg = KkfcContrastPair(
    name: 'success on success-bg',
    foreground: KkfcColors.success,
    background: KkfcColors.successBg,
    contrastRatio: 5.75,
  );

  /// warning on warning-bg (6.69:1)
  static const KkfcContrastPair warningOnWarningBg = KkfcContrastPair(
    name: 'warning on warning-bg',
    foreground: KkfcColors.warning,
    background: KkfcColors.warningBg,
    contrastRatio: 6.69,
  );

  /// danger on danger-bg (5.67:1)
  static const KkfcContrastPair dangerOnDangerBg = KkfcContrastPair(
    name: 'danger on danger-bg',
    foreground: KkfcColors.danger,
    background: KkfcColors.dangerBg,
    contrastRatio: 5.67,
  );

  /// on-warning-solid on warning-solid (8.43:1)
  static const KkfcContrastPair onWarningSolidOnWarningSolid = KkfcContrastPair(
    name: 'on-warning-solid on warning-solid',
    foreground: KkfcColors.onWarningSolid,
    background: KkfcColors.warningSolid,
    contrastRatio: 8.43,
  );

  /// All 15 contrast pairs in order of appearance in the specification.
  static const List<KkfcContrastPair> all = [
    inkOnCanvas,
    ink2OnCanvas,
    ink3OnCanvas,
    onSelectedOnSelected,
    onSolidOnAction,
    actionInkOnSurface,
    onShellSelectedOnShellSelected,
    onAccentOnAccent,
    neutralOnNeutralBg,
    infoOnInfoBg,
    reviewOnReviewBg,
    successOnSuccessBg,
    warningOnWarningBg,
    dangerOnDangerBg,
    onWarningSolidOnWarningSolid,
  ];
}
