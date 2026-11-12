import 'package:flutter/material.dart';

export 'color_tokens.dart';
export 'status_colors.dart';

/// 4-based spacing scale matching the design system:
/// space-1 (4) to space-16 (64).
abstract final class KkfcSpace {
  static const s0 = 0.0;
  static const s2 = 2.0;
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
  static const s40 = 40.0;
  static const s48 = 48.0;
  static const s64 = 64.0;

  // Design system aliases (--k-space-*)
  /// `--k-space-1`: 4px
  static const space1 = 4.0;

  /// `--k-space-2`: 8px
  static const space2 = 8.0;

  /// `--k-space-3`: 12px
  static const space3 = 12.0;

  /// `--k-space-4`: 16px
  static const space4 = 16.0;

  /// `--k-space-5`: 20px
  static const space5 = 20.0;

  /// `--k-space-6`: 24px
  static const space6 = 24.0;

  /// `--k-space-8`: 32px
  static const space8 = 32.0;

  /// `--k-space-10`: 40px
  static const space10 = 40.0;

  /// `--k-space-12`: 48px
  static const space12 = 48.0;

  /// `--k-space-16`: 64px
  static const space16 = 64.0;
}

/// Corner radius tokens matching the design system:
/// radius-sm: 6, radius-md: 10, radius-lg: 14, radius-pill: 999.
abstract final class KkfcRadius {
  static const none = 0.0;

  /// `--k-radius-sm`: 6px
  static const sm = 6.0;
  static const radiusSm = 6.0;

  /// `--k-radius-md`: 10px
  static const md = 10.0;
  static const radiusMd = 10.0;

  /// `--k-radius-lg`: 14px
  static const lg = 14.0;
  static const radiusLg = 14.0;

  /// `--k-radius-pill`: 999px
  static const pill = 999.0;
  static const radiusPill = 999.0;
  static const full = 999.0;
}

/// Touch target sizes matching the design system:
/// Web control: 40px, POS minimum: 48px, POS primary: 56px.
abstract final class KkfcTargets {
  /// Web control target size: 40px
  static const webControl = 40.0;

  /// POS minimum touch target: 48px
  static const posMinimum = 48.0;

  /// POS primary action touch target: 56px
  static const posPrimary = 56.0;
}

abstract final class KkfcBorderWidth {
  static const thin = 1.0;
  static const thick = 2.0;
  static const focus = 3.0;
}

/// Sizing tokens for layout components, controls, and shells.
abstract final class KkfcSizing {
  static const touchMin = 48.0;
  static const controlMd = 48.0;
  static const controlLg = 56.0;
  static const input = 56.0;
  static const badge = 32.0;
  static const ticketMax = 340.0;
  static const laneMin = 280.0;
  static const iconSm = 20.0;
  static const iconMd = 24.0;
  static const iconLg = 32.0;
  static const iconXl = 48.0;

  /// Staff POS: 56px navy app bar
  static const appBar = 56.0;

  /// Staff POS: 96px rail from 900px
  static const navRail = 96.0;

  /// Web: 248px navy sidebar
  static const webSidebar = 248.0;

  /// Web: 72px rail
  static const webRail = 72.0;

  /// Content max width: 1600px
  static const contentMax = 1600.0;

  static const row = 56.0;
  static const switchTrack = 52.0;
  static const thumb = 48.0;
  static const panel = 400.0;

  // Target aliases
  static const targetWeb = KkfcTargets.webControl;
  static const targetPosMin = KkfcTargets.posMinimum;
  static const targetPosPrimary = KkfcTargets.posPrimary;
}

/// Responsive breakpoints matching the design system:
/// 320, 360, 390, 768, 900, 1024, 1280, 1440, 1920.
abstract final class KkfcBreakpoints {
  /// 320px: Smallest supported. 200% zoom reflow
  static const double min = 320.0;

  /// 360px: Android phones
  static const double androidPhone = 360.0;

  /// 390px: iPhone: POS primary width in this file
  static const double iphone = 390.0;

  /// 768px: Tablet portrait. Kitchen shows 2x2 lanes
  static const double tabletPortrait = 768.0;

  /// 900px: POS rail replaces bottom nav. Side panels on ordering and kitchen
  static const double rail = 900.0;

  /// 1024px: Web sidebar stops being a drawer. POS tablet landscape
  static const double tabletLandscape = 1024.0;

  /// 1280px: Staff list and profile sit side by side
  static const double splitProfile = 1280.0;

  /// 1440px: Web primary width in this file
  static const double webPrimary = 1440.0;

  /// 1920px: Web wide. Content max 1600
  static const double webWide = 1920.0;
}

/// Motion system matching the design system:
/// Every control feels physical, selection travels instead of jumping,
/// and only confirmed results get a flourish.
abstract final class KkfcMotion {
  // --- Durations ---
  /// `--k-dur-press`: 90ms (Finger down: instant acknowledgement)
  static const durPress = Duration(milliseconds: 90);

  /// `--k-dur-micro`: 150ms (Hover, focus, selection colour, value change)
  static const durMicro = Duration(milliseconds: 150);

  /// `--k-dur-exit`: 140ms (Anything leaving. Always quicker than arriving)
  static const durExit = Duration(milliseconds: 140);

  /// `--k-dur-overlay`: 220ms (Menus, scrims, dialogs, toasts entering)
  static const durOverlay = Duration(milliseconds: 220);

  /// `--k-dur-screen`: 240ms (Screen and tab changes)
  static const durScreen = Duration(milliseconds: 240);

  /// `--k-dur-release`: 280ms (Finger up, selection sliding between options)
  static const durRelease = Duration(milliseconds: 280);

  /// `--k-dur-layout`: 320ms (Drawers, sheets, sidebar width, tickets changing lane)
  static const durLayout = Duration(milliseconds: 320);

  /// `--k-dur-focal`: 520ms (Sent to kitchen, item into cart)
  static const durFocal = Duration(milliseconds: 520);

  // --- Legacy and convenience aliases ---
  static const fast = durPress;
  static const base = durScreen;
  static const slow = durLayout;
  static const overlay = durOverlay;

  /// Rows follow each other in, 18ms apart, capped at 10 rows
  static const stagger = Duration(milliseconds: 18);
  static const staggerMaxRows = 10;

  static const undo = Duration(milliseconds: 5000);
  static const toast = Duration(milliseconds: 4000);

  // --- Curves ---
  /// `--k-ease-out`: Arrivals
  static const easeOut = Curves.easeOut;

  /// `--k-ease-in`: Exits
  static const easeIn = Curves.easeIn;

  /// `--k-ease-move`: Moving within a view
  static const easeMove = Curves.easeInOut;

  /// `--k-ease-spring`: Soft spring, 5% overshoot: confirmed, physical moments only
  static const easeSpring = Cubic(0.34, 1.3, 0.64, 1.0);

  // --- Behaviours ---
  /// Every control scales to 0.97 fast on press and returns on the spring
  static const pressScale = 0.97;

  /// Peers fade up 6px
  static const peerOffset = 6.0;

  /// Deeper / back navigation lateral offset: 14px
  static const routeOffset = 14.0;
}

/// Elevation tokens:
/// One soft shadow family from navy (#19293E).
/// Overlays only; resting cards use a 1px border.
abstract final class KkfcElevation {
  /// Base shadow color from navy
  static const Color shadowColor = Color(0xFF19293E);

  /// shadow-1: Subtle lift
  static const List<BoxShadow> shadow1 = [
    BoxShadow(color: Color(0x0F19293E), blurRadius: 4, offset: Offset(0, 1)),
  ];

  /// shadow-2: Hover on a clickable card
  static const List<BoxShadow> shadow2 = [
    BoxShadow(color: Color(0x1419293E), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x0A19293E), blurRadius: 4, offset: Offset(0, 1)),
  ];

  /// shadow-3: Dialogs, sheets, drawers, toasts
  static const List<BoxShadow> shadow3 = [
    BoxShadow(color: Color(0x2419293E), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x1419293E), blurRadius: 8, offset: Offset(0, 2)),
  ];
}

abstract final class KkfcOpacity {
  static const hover = 0.08;
  static const pressed = 0.10;
  static const scrim = 0.50;
  static const soft = 0.72;
  static const line = 0.20;
  static const disabled = 0.38;
}

abstract final class KkfcKitchen {
  // PROPOSAL values in the design system; confirm with client.
  static const ageCautionMin = 5;
  static const ageLateMin = 8;
}
