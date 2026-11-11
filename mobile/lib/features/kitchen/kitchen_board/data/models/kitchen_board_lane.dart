import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

/// The four operational columns on the Kitchen Display System (KDS) board.
enum KitchenBoardLane {
  queued,
  preparing,
  qcCheck,
  ready;

  String get title => switch (this) {
    KitchenBoardLane.queued => 'Queued',
    KitchenBoardLane.preparing => 'Preparing',
    KitchenBoardLane.qcCheck => 'QC check',
    KitchenBoardLane.ready => 'Ready',
  };

  String get emptyMessage => switch (this) {
    KitchenBoardLane.queued => 'Nothing queued',
    KitchenBoardLane.preparing => 'Nothing preparing',
    KitchenBoardLane.qcCheck => 'Nothing waiting for QC',
    KitchenBoardLane.ready => 'Nothing ready for handover',
  };

  IconData get icon => switch (this) {
    KitchenBoardLane.queued => Icons.format_list_bulleted_rounded,
    KitchenBoardLane.preparing => Icons.local_fire_department_outlined,
    KitchenBoardLane.qcCheck => Icons.search_rounded,
    KitchenBoardLane.ready => Icons.check_rounded,
  };

  Color get headerForeground => switch (this) {
    KitchenBoardLane.queued => KkfcColors.neutral,
    KitchenBoardLane.preparing => KkfcColors.info,
    KitchenBoardLane.qcCheck => KkfcColors.review,
    KitchenBoardLane.ready => KkfcColors.success,
  };

  Color get headerBackground => switch (this) {
    KitchenBoardLane.queued => KkfcColors.neutralBg,
    KitchenBoardLane.preparing => KkfcColors.infoBg,
    KitchenBoardLane.qcCheck => KkfcColors.reviewBg,
    KitchenBoardLane.ready => KkfcColors.successBg,
  };

  Color get headerBorder => switch (this) {
    KitchenBoardLane.queued => KkfcColors.neutralBorder,
    KitchenBoardLane.preparing => KkfcColors.infoBorder,
    KitchenBoardLane.qcCheck => KkfcColors.reviewBorder,
    KitchenBoardLane.ready => KkfcColors.successBorder,
  };

  Color get badgeTextColor => switch (this) {
    KitchenBoardLane.queued => KkfcColors.ink,
    KitchenBoardLane.preparing => KkfcColors.info,
    KitchenBoardLane.qcCheck => KkfcColors.review,
    KitchenBoardLane.ready => KkfcColors.success,
  };

  /// Maps a [KkfcStatus] to its corresponding [KitchenBoardLane],
  /// or returns `null` for terminal/non-board statuses.
  static KitchenBoardLane? fromStatus(KkfcStatus status) => switch (status) {
    KkfcStatus.queued => KitchenBoardLane.queued,
    KkfcStatus.acknowledged ||
    KkfcStatus.preparing ||
    KkfcStatus.reworking => KitchenBoardLane.preparing,
    KkfcStatus.checking => KitchenBoardLane.qcCheck,
    KkfcStatus.ready => KitchenBoardLane.ready,
    _ => null,
  };

  /// Resolves the primary CTA label shown on a ticket card in this lane.
  String actionLabelFor(KkfcStatus status) => switch (this) {
    KitchenBoardLane.queued => 'Acknowledge',
    KitchenBoardLane.preparing => status == KkfcStatus.reworking
        ? 'Open rework'
        : (status == KkfcStatus.acknowledged ? 'Start Preparing' : 'Send to QC'),
    KitchenBoardLane.qcCheck => 'QC check',
    KitchenBoardLane.ready => 'Hand over',
  };
}
