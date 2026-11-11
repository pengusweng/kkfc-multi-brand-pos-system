import 'package:flutter/material.dart';

import 'package:mobile/core/models/order_status.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

import 'color_tokens.dart';
import 'semantic_colors.dart';

/// Resolved color set for a kitchen ticket status.
@immutable
class KkfcTicketStatusColor {
  const KkfcTicketStatusColor({
    required this.background,
    required this.border,
    required this.foreground,
    required this.accent,
    required this.cardBorder,
  });

  /// Tinted background for the status badge / chip.
  final Color background;

  /// Border for the status badge / chip.
  final Color border;

  /// Text and icon ink color.
  final Color foreground;

  /// Prominent accent color for top card bar, solid fills, and indicators.
  final Color accent;

  /// Subtle card border color matching the status tone.
  final Color cardBorder;
}

/// Palette mapping each [KkfcStatus] to its status badge and card colors.
abstract final class KkfcTicketStatusColors {
  /// Slate color set for queued status.
  static const queued = KkfcTicketStatusColor(
    background: KkfcColors.statusQueuedBg,
    border: KkfcColors.statusQueuedBorder,
    foreground: KkfcColors.statusQueuedFg,
    accent: KkfcColors.statusQueuedSolid,
    cardBorder: KkfcColors.statusQueuedCardBorder,
  );

  /// Darker shade of blue for acknowledged status.
  static const acknowledged = KkfcTicketStatusColor(
    background: KkfcColors.statusAcknowledgedBg,
    border: KkfcColors.statusAcknowledgedBorder,
    foreground: KkfcColors.statusAcknowledgedFg,
    accent: KkfcColors.statusAcknowledgedSolid,
    cardBorder: KkfcColors.statusAcknowledgedCardBorder,
  );

  /// Lighter shade of blue for preparing status.
  static const preparing = KkfcTicketStatusColor(
    background: KkfcColors.statusPreparingBg,
    border: KkfcColors.statusPreparingBorder,
    foreground: KkfcColors.statusPreparingFg,
    accent: KkfcColors.statusPreparingSolid,
    cardBorder: KkfcColors.statusPreparingCardBorder,
  );

  /// Violet color set for QC check / checking status.
  static const checking = KkfcTicketStatusColor(
    background: KkfcColors.statusCheckingBg,
    border: KkfcColors.statusCheckingBorder,
    foreground: KkfcColors.statusCheckingFg,
    accent: KkfcColors.statusCheckingSolid,
    cardBorder: KkfcColors.statusCheckingCardBorder,
  );

  /// Copper / amber color set for rework status.
  static const reworking = KkfcTicketStatusColor(
    background: KkfcColors.reworkBg,
    border: KkfcColors.reworkBorder,
    foreground: KkfcColors.reworkText,
    accent: KkfcColors.reworkSolid,
    cardBorder: KkfcColors.reworkCardBorder,
  );

  /// Green color set for ready status.
  static const ready = KkfcTicketStatusColor(
    background: KkfcColors.statusReadyBg,
    border: KkfcColors.statusReadyBorder,
    foreground: KkfcColors.statusReadyFg,
    accent: KkfcColors.statusReadySolid,
    cardBorder: KkfcColors.statusReadyCardBorder,
  );

  /// Resolves the ticket status colors for any [KkfcStatus].
  static KkfcTicketStatusColor forStatus(KkfcStatus status) => switch (status) {
    KkfcStatus.queued => queued,
    KkfcStatus.acknowledged => acknowledged,
    KkfcStatus.preparing => preparing,
    KkfcStatus.checking => checking,
    KkfcStatus.reworking => reworking,
    KkfcStatus.ready => ready,
    _ => queued,
  };
}

@immutable
class KkfcStatusColors extends ThemeExtension<KkfcStatusColors> {
  const KkfcStatusColors({
    required this.draft,
    required this.queued,
    required this.acknowledged,
    required this.preparing,
    required this.checking,
    required this.reworking,
    required this.ready,
    required this.handedOver,
    required this.cancelled,
  });

  final KkfcTone draft;
  final KkfcTone queued;
  final KkfcTone acknowledged;
  final KkfcTone preparing;
  final KkfcTone checking;
  final KkfcTone reworking;
  final KkfcTone ready;
  final KkfcTone handedOver;
  final KkfcTone cancelled;

  /// Exhaustive: adding an OrderStatus without a field here is a compile error.
  KkfcTone toneFor(OrderStatus status) => switch (status) {
    OrderStatus.draft => draft,
    OrderStatus.queued => queued,
    OrderStatus.acknowledged => acknowledged,
    OrderStatus.preparing => preparing,
    OrderStatus.checking => checking,
    OrderStatus.reworking => reworking,
    OrderStatus.ready => ready,
    OrderStatus.handedOver => handedOver,
    OrderStatus.cancelled => cancelled,
  };

  // Light (counter), matching the Colour Language specification:
  // - Slate (waiting or inactive): draft, queued, handedOver, cancelled
  // - Blue (in progress or FYI): acknowledged (soft), preparing (solid)
  // - Violet (waiting on a check): checking (soft), reworking (solid)
  // - Green (done and fine): ready (solid)
  static const light = KkfcStatusColors(
    draft: KkfcTone(
      bg: KkfcColors.neutralBg, // --k-neutral-bg (#EDF0F4)
      fg: KkfcColors.neutral, // --k-neutral (#46566C)
      border: KkfcColors.neutralBorder, // --k-neutral-border (#D3DDE2)
    ),
    queued: KkfcTone(
      bg: KkfcColors.neutralBg, // --k-neutral-bg (#EDF0F4)
      fg: KkfcColors.neutral, // --k-neutral (#46566C)
      border: KkfcColors.neutralBorder, // --k-neutral-border (#D3DDE2)
    ),
    acknowledged: KkfcTone(
      bg: KkfcColors.statusAcknowledgedBg, // darker blue tint (#D8E6F5)
      fg: KkfcColors.statusAcknowledgedFg, // darker blue text (#0D3B66)
      border: KkfcColors.statusAcknowledgedBorder, // darker blue border (#8EB5E0)
    ),
    preparing: KkfcTone(
      bg: KkfcColors.statusPreparingBg, // lighter blue tint (#EDF7FF)
      fg: KkfcColors.statusPreparingFg, // lighter blue text (#0369A1)
      border: KkfcColors.statusPreparingBorder, // lighter blue border (#BAE6FD)
    ),
    checking: KkfcTone(
      bg: KkfcColors.reviewBg, // --k-review-bg (#F0ECFB)
      fg: KkfcColors.review, // --k-review (#5A3EA6)
      border: KkfcColors.reviewBorder, // --k-review-border (#C8BBEC)
    ),
    reworking: KkfcTone(
      bg: KkfcColors.reviewSolid, // --k-review-solid (#6346B5)
      fg: KkfcColors.onSolid, // --k-on-solid (#FFFFFF)
      border: KkfcColors.reviewSolid,
    ),
    ready: KkfcTone(
      bg: KkfcColors.successSolid, // --k-success-solid (#187A42)
      fg: KkfcColors.onSolid, // --k-on-solid (#FFFFFF)
      border: KkfcColors.successSolid,
    ),
    handedOver: KkfcTone(
      bg: KkfcColors.neutralBg, // --k-neutral-bg (#EDF0F4)
      fg: KkfcColors.neutral, // --k-neutral (#46566C)
      border: KkfcColors.neutralBorder, // --k-neutral-border (#D3DDE2)
    ),
    cancelled: KkfcTone(
      bg: KkfcColors.neutralBg, // --k-neutral-bg (#EDF0F4)
      fg: KkfcColors.neutralSolid, // --k-neutral-solid (#586579)
      border: KkfcColors.neutralBorder, // --k-neutral-border (#D3DDE2)
    ),
  );

  // Dark (kitchen), from theme/dark status
  static const dark = KkfcStatusColors(
    draft: KkfcTone(
      bg: Color(0xFF1D2940),
      fg: Color(0xFFC7CFDD),
      border: Color(0xFF374763),
    ),
    queued: KkfcTone(
      bg: Color(0xFF1D2940),
      fg: Color(0xFFC7CFDD),
      border: Color(0xFF374763),
    ),
    acknowledged: KkfcTone(
      bg: Color(0xFF0C1D3F),
      fg: KkfcColors.infoBorder,
      border: KkfcColors.info,
    ),
    preparing: KkfcTone(
      bg: KkfcColors.infoSolid,
      fg: KkfcColors.onSolid,
      border: KkfcColors.infoSolid,
    ),
    checking: KkfcTone(
      bg: Color(0xFF330D2C),
      fg: KkfcColors.reviewBorder,
      border: KkfcColors.review,
    ),
    reworking: KkfcTone(
      bg: KkfcColors.reviewSolid,
      fg: KkfcColors.onSolid,
      border: KkfcColors.reviewSolid,
    ),
    ready: KkfcTone(
      bg: KkfcColors.successSolid,
      fg: KkfcColors.onSolid,
      border: KkfcColors.successSolid,
    ),
    handedOver: KkfcTone(
      bg: Color(0xFF141D2E),
      fg: Color(0xFF9CA9C0),
      border: Color(0xFF283650),
    ),
    cancelled: KkfcTone(
      bg: Color(0xFF141D2E),
      fg: Color(0xFF9CA9C0),
      border: Color(0xFF283650),
    ),
  );

  @override
  KkfcStatusColors copyWith({
    KkfcTone? draft,
    KkfcTone? queued,
    KkfcTone? acknowledged,
    KkfcTone? preparing,
    KkfcTone? checking,
    KkfcTone? reworking,
    KkfcTone? ready,
    KkfcTone? handedOver,
    KkfcTone? cancelled,
  }) {
    return KkfcStatusColors(
      draft: draft ?? this.draft,
      queued: queued ?? this.queued,
      acknowledged: acknowledged ?? this.acknowledged,
      preparing: preparing ?? this.preparing,
      checking: checking ?? this.checking,
      reworking: reworking ?? this.reworking,
      ready: ready ?? this.ready,
      handedOver: handedOver ?? this.handedOver,
      cancelled: cancelled ?? this.cancelled,
    );
  }

  @override
  KkfcStatusColors lerp(ThemeExtension<KkfcStatusColors>? other, double t) {
    if (other is! KkfcStatusColors) return this;
    return KkfcStatusColors(
      draft: KkfcTone.lerp(draft, other.draft, t),
      queued: KkfcTone.lerp(queued, other.queued, t),
      acknowledged: KkfcTone.lerp(acknowledged, other.acknowledged, t),
      preparing: KkfcTone.lerp(preparing, other.preparing, t),
      checking: KkfcTone.lerp(checking, other.checking, t),
      reworking: KkfcTone.lerp(reworking, other.reworking, t),
      ready: KkfcTone.lerp(ready, other.ready, t),
      handedOver: KkfcTone.lerp(handedOver, other.handedOver, t),
      cancelled: KkfcTone.lerp(cancelled, other.cancelled, t),
    );
  }
}
