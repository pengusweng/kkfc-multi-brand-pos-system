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
abstract final class KkfcColors {
  // --- Warm sand: ground ---
  /// `--k-canvas`: Canvas ground where work sits
  static const Color canvas = Color(0xFFF7F3EC);

  /// `--k-canvas-sunken`: Sunken ground
  static const Color canvasSunken = Color(0xFFEEE8DC);

  /// `--k-surface`: Default surface
  static const Color surface = Color(0xFFFFFFFF);

  /// `--k-surface-subtle`: Subtle surface
  static const Color surfaceSubtle = Color(0xFFFBF9F5);

  /// `--k-border`: Default border
  static const Color border = Color(0xFFDDD6C9);

  /// `--k-divider`: Divider line
  static const Color divider = Color(0xFFEDE8DF);

  /// `--k-border-strong`: Control boundary (3:1 contrast ratio)
  static const Color borderStrong = Color(0xFF76849A);

  // --- Navy: structure and "you are here" ---
  /// `--k-shell`: Main shell background
  static const Color shell = Color(0xFF19293E);

  /// `--k-shell-raised`: Raised shell surface
  static const Color shellRaised = Color(0xFF293F58);

  /// `--k-selected`: Selected state (chips, tabs, segmented options, bottom nav)
  static const Color selected = Color(0xFF1D2940);

  /// `--k-selected-tint`: Tinted surface for selected items
  static const Color selectedTint = Color(0xFFE7ECF4);

  /// `--k-ink`: Primary text / typography ink
  static const Color ink = Color(0xFF19293E);

  /// `--k-ink-2`: Secondary text ink
  static const Color ink2 = Color(0xFF43536A);

  /// `--k-ink-3`: Minimum contrast text ink / muted
  static const Color ink3 = Color(0xFF586579);

  // --- Copper: "do this next" ---
  /// `--k-action`: Primary action button / element
  static const Color action = Color(0xFFA8562A);

  /// `--k-action-hover`: Action hover state
  static const Color actionHover = Color(0xFF8E4722);

  /// `--k-action-pressed`: Action pressed state
  static const Color actionPressed = Color(0xFF743A1B);

  /// `--k-action-ink`: Copper text
  static const Color actionInk = Color(0xFF8E4722);

  /// `--k-action-tint`: Action tinted background
  static const Color actionTint = Color(0xFFF9EBE2);

  /// `--k-identity`: Brand identity (non-text)
  static const Color identity = Color(0xFFB86843);

  // --- Orange: attention on navy ---
  /// `--k-accent`: Sidebar counts / attention on navy
  static const Color accent = Color(0xFFFF9248);

  /// `--k-focus-on-shell`: Focus ring when placed on navy shell
  static const Color focusOnShell = Color(0xFFFFC18E);

  // --- Slate: waiting or inactive ---
  /// `--k-neutral`: Slate ink (queued, draft, not recorded, inactive)
  static const Color neutral = Color(0xFF46566C);

  /// `--k-neutral-bg`: Slate tinted background
  static const Color neutralBg = Color(0xFFEDF0F4);

  /// `--k-neutral-border`: Slate border
  static const Color neutralBorder = Color(0xFFD3DDE2);

  /// `--k-neutral-solid`: Slate solid fill
  static const Color neutralSolid = Color(0xFF586579);

  // --- Blue: in progress or FYI ---
  /// `--k-info`: Blue ink (preparing, information)
  static const Color info = Color(0xFF1B5A96);

  /// `--k-info-bg`: Blue tinted background
  static const Color infoBg = Color(0xFFE6F0FA);

  /// `--k-info-border`: Blue border
  static const Color infoBorder = Color(0xFFA5C6E8);

  /// `--k-info-solid`: Blue solid fill
  static const Color infoSolid = Color(0xFF1F67AB);

  /// `--k-focus`: Primary focus ring
  static const Color focus = Color(0xFF1F66C9);

  // --- Violet: waiting on a check ---
  /// `--k-review`: Violet ink (QC check, review, pending approval)
  static const Color review = Color(0xFF5A3EA6);

  /// `--k-review-bg`: Violet tinted background
  static const Color reviewBg = Color(0xFFF0ECFB);

  /// `--k-review-border`: Violet border
  static const Color reviewBorder = Color(0xFFC8BBEC);

  /// `--k-review-solid`: Violet solid fill
  static const Color reviewSolid = Color(0xFF6346B5);

  // --- Green: done and fine ---
  /// `--k-success`: Green ink (ready, accepted, active, success)
  static const Color success = Color(0xFF166B3A);

  /// `--k-success-bg`: Green tinted background
  static const Color successBg = Color(0xFFE3F4E9);

  /// `--k-success-border`: Green border
  static const Color successBorder = Color(0xFF9ED2B0);

  /// `--k-success-solid`: Green solid fill
  static const Color successSolid = Color(0xFF187A42);

  // --- Gold: look at this, not blocking ---
  /// `--k-warning`: Gold ink (setup pending, variance, kitchen notes)
  static const Color warning = Color(0xFF6A5200);

  /// `--k-warning-bg`: Gold tinted background
  static const Color warningBg = Color(0xFFFCF3CF);

  /// `--k-warning-border`: Gold border
  static const Color warningBorder = Color(0xFFDDBE55);

  /// `--k-warning-solid`: Gold solid fill
  static const Color warningSolid = Color(0xFFEDBE3D);

  // --- Red: blocked, failed, late ---
  /// `--k-danger`: Red ink (late from 15:00, denied, failed, destructive)
  static const Color danger = Color(0xFFB3261E);

  /// `--k-danger-bg`: Red tinted background
  static const Color dangerBg = Color(0xFFFCEBEA);

  /// `--k-danger-border`: Red border
  static const Color dangerBorder = Color(0xFFEDB3AF);

  /// `--k-danger-solid`: Red solid fill
  static const Color dangerSolid = Color(0xFFB3261E);
}
