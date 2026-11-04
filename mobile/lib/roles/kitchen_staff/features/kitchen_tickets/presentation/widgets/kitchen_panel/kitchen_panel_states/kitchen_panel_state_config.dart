import 'package:flutter/material.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

/// Resolved presentation values for a single [KitchenTicketPanelState].
///
/// Each state file under `kitchen_panel_states` returns one of these, and the
/// shared [KitchenTicketDetailPanel] scaffold renders it.
class KitchenPanelStateConfig {
  const KitchenPanelStateConfig({
    required this.badgeText,
    required this.badgeColor,
    required this.headerBackgroundColor,
    required this.title,
    required this.subtitle,
    required this.confirmTitle,
    required this.confirmTitleColor,
    required this.confirmItems,
    required this.permissionNotice,
    required this.backLabel,
    required this.actionLabel,
    required this.onBack,
    required this.onAction,
    this.topAccentColor,
    this.statusOverride,
    this.isQC = false,
    this.isActionEnabled = true,
    this.showCheckIcon = true,
    this.showReasonField = false,
    this.footer,
  });

  final String badgeText;
  final Color badgeColor;
  final Color headerBackgroundColor;
  final Color? topAccentColor;

  final String title;
  final String subtitle;

  final String confirmTitle;
  final Color confirmTitleColor;
  final List<String> confirmItems;
  final bool showCheckIcon;
  final Widget? footer;

  final String permissionNotice;
  final bool showReasonField;

  final KkfcStatus? statusOverride;

  final String backLabel;
  final String actionLabel;
  final VoidCallback? onBack;
  final VoidCallback? onAction;

  final bool isQC;
  final bool isActionEnabled;
}
