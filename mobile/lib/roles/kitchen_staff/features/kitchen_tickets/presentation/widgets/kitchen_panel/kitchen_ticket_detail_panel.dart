import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/data/models/kitchen_board_sample_data.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/data/models/kitchen_ticket_panel_state.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_actions.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_confirm_checklist.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_header.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_permission_banner.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/kitchen_panel_state_context.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/kitchen_panel_state_resolver.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_ticket_info.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_breakpoints.dart';

/// The ticket detail panel (right panel on tablet, full queue detail on phone).
///
/// Designed as a stateless component with sample data defaults and callbacks
/// for closing the panel or acknowledging the ticket. State-specific content
/// is resolved from the files under `kitchen_panel_states`.
class KitchenTicketDetailPanel extends StatelessWidget {
  const KitchenTicketDetailPanel({
    super.key,
    this.ticket = KitchenBoardSampleData.t014,
    this.panelState = KitchenTicketPanelState.queued,
    this.onClose,
    this.onBack,
    this.onAcknowledge,
    this.onBeginPreparation,
    this.onSendToQC,
    this.onPassQC,
    this.onFailQC,
    this.onBackToQC,
    this.onUseSampleReason,
    this.onSubmitReason,
    this.onTestBlankReason,
    this.onConfirmQCFail,
    this.failureReasonText,
    this.onReturnToQC,
    this.onContinueToHandover,
    this.onAddPhoto,
    this.onRetakePhoto,
    this.onSubmitPhoto,
    this.onConfirmHandover,
    this.onNotYet,
    this.onBackToKitchenBoard,
    this.onHistoryPending,
    this.reasonController,
    this.onReasonChanged,
    this.reasonPlaceholder,
    this.width,
    this.borderRadius,
    this.badgeText,
    this.title,
    this.subtitle,
    this.backButtonLabel,
    this.acknowledgeButtonLabel,
    this.paymentStatus = 'PAYMENT · UNPAID',
    this.confirmationTitle,
    this.confirmationItems,
    this.permissionNotice,
  });

  /// Ticket data to display (defaults to T-014 sample data).
  final KitchenBoardItem ticket;

  /// Whether the panel is in queued, acknowledged, preparing, quality check, or ready state.
  final KitchenTicketPanelState panelState;

  /// Callback when user taps close button "×" or back button.
  final VoidCallback? onClose;

  /// Optional specific callback for the back button. Defaults to [onClose].
  final VoidCallback? onBack;

  /// Callback when user taps "Acknowledge ticket".
  final VoidCallback? onAcknowledge;

  /// Callback when user taps "Begin preparation".
  final VoidCallback? onBeginPreparation;

  /// Callback when user taps "Send to QC".
  final VoidCallback? onSendToQC;

  /// Callback when user taps "Pass QC".
  final VoidCallback? onPassQC;

  /// Callback when user taps "Fail QC".
  final VoidCallback? onFailQC;

  /// Callback when user taps "Back to QC".
  final VoidCallback? onBackToQC;

  /// Callback when user taps "Use sample reason" / "Submit reason".
  final VoidCallback? onUseSampleReason;

  /// Optional specific callback for "Submit reason". Defaults to [onUseSampleReason].
  final VoidCallback? onSubmitReason;

  /// Callback when user taps "Test blank reason".
  final VoidCallback? onTestBlankReason;

  /// Callback when user taps "Confirm QC fail".
  final VoidCallback? onConfirmQCFail;

  /// Submitted reason text displayed in [KitchenTicketPanelState.qcFailureReason].
  final String? failureReasonText;

  /// Callback when user taps "Return to QC".
  final VoidCallback? onReturnToQC;

  /// Callback when user taps "Continue to handover".
  final VoidCallback? onContinueToHandover;

  /// Callback when user taps "Add photo".
  final VoidCallback? onAddPhoto;

  /// Callback when user taps "Retake photo".
  final VoidCallback? onRetakePhoto;

  /// Callback when user taps "Submit photo".
  final VoidCallback? onSubmitPhoto;

  /// Callback when user taps "Confirm handover".
  final VoidCallback? onConfirmHandover;

  /// Callback when user taps "Not yet".
  final VoidCallback? onNotYet;

  /// Callback when user taps "Back to Kitchen Board".
  final VoidCallback? onBackToKitchenBoard;

  /// Callback when user taps "History (pending)".
  final VoidCallback? onHistoryPending;

  /// Optional controller for the QC reason text field in [KitchenTicketPanelState.missingQCReason].
  final TextEditingController? reasonController;

  /// Callback when QC reason text field changes.
  final ValueChanged<String>? onReasonChanged;

  /// Custom placeholder for the reason text field. Defaults to 'Enter reason...'.
  final String? reasonPlaceholder;

  /// Optional fixed width for the panel (e.g. 400 or 440 on tablet).
  final double? width;

  /// Optional border radius (defaults to zero for flush docked right panel).
  final BorderRadiusGeometry? borderRadius;

  final String? badgeText;
  final String? title;
  final String? subtitle;
  final String? backButtonLabel;
  final String? acknowledgeButtonLabel;
  final String paymentStatus;
  final String? confirmationTitle;
  final List<String>? confirmationItems;
  final String? permissionNotice;

  void _handleDismiss() {
    if (onClose != null) {
      onClose!();
    } else if (onBack != null) {
      onBack!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketData = ticket.ticket;
    final rawNumber = ticketData.ticketNumber.replaceFirst('Ticket ', '');

    final stateConfig = resolveKitchenPanelState(
      panelState,
      KitchenPanelStateContext(
        isTablet: context.isKitchenTablet,
        ticket: ticket,
        rawNumber: rawNumber,
        dismiss: _handleDismiss,
        onClose: onClose,
        onBack: onBack,
        onAcknowledge: onAcknowledge,
        onBeginPreparation: onBeginPreparation,
        onSendToQC: onSendToQC,
        onPassQC: onPassQC,
        onFailQC: onFailQC,
        onBackToQC: onBackToQC,
        onUseSampleReason: onUseSampleReason,
        onSubmitReason: onSubmitReason,
        onTestBlankReason: onTestBlankReason,
        onConfirmQCFail: onConfirmQCFail,
        failureReasonText: failureReasonText,
        onReturnToQC: onReturnToQC,
        onContinueToHandover: onContinueToHandover,
        onAddPhoto: onAddPhoto,
        onRetakePhoto: onRetakePhoto,
        onSubmitPhoto: onSubmitPhoto,
        onConfirmHandover: onConfirmHandover,
        onNotYet: onNotYet,
        onBackToKitchenBoard: onBackToKitchenBoard,
        onHistoryPending: onHistoryPending,
        reasonController: reasonController,
        onReasonChanged: onReasonChanged,
        reasonPlaceholder: reasonPlaceholder,
      ),
    );

    final resolvedBadgeText = badgeText ?? stateConfig.badgeText;
    final resolvedTitle = title ?? stateConfig.title;
    final resolvedSubtitle = subtitle ?? stateConfig.subtitle;
    final resolvedConfirmTitle = confirmationTitle ?? stateConfig.confirmTitle;
    final resolvedConfirmItems = confirmationItems ?? stateConfig.confirmItems;
    final resolvedPermissionNotice =
        permissionNotice ?? stateConfig.permissionNotice;
    final resolvedBackLabel = backButtonLabel ?? stateConfig.backLabel;
    final resolvedActionLabel =
        acknowledgeButtonLabel ?? stateConfig.actionLabel;

    final panelWidget = Container(
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: borderRadius ?? BorderRadius.zero,
        border: const Border(
          left: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 16,
            offset: Offset(-4, 0),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          KitchenPanelHeader(
            badgeText: resolvedBadgeText,
            badgeColor: stateConfig.badgeColor,
            backgroundColor: stateConfig.headerBackgroundColor,
            topAccentColor: stateConfig.topAccentColor,
            title: resolvedTitle,
            subtitle: resolvedSubtitle,
            onClose: _handleDismiss,
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          // Scrollable Body Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KitchenPanelTicketInfo(
                    ticket: ticketData,
                    statusOverride: stateConfig.statusOverride,
                    paymentStatus: paymentStatus,
                  ),
                  const SizedBox(height: 12),
                  KitchenPanelConfirmChecklist(
                    title: resolvedConfirmTitle,
                    titleColor: stateConfig.confirmTitleColor,
                    items: resolvedConfirmItems,
                    showCheckIcon: stateConfig.showCheckIcon,
                    footer: stateConfig.footer,
                  ),
                  const SizedBox(height: 12),
                  if (stateConfig.showReasonField)
                    Container(
                      key: const ValueKey('kitchen_panel_qc_reason_field'),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFCBD5E1),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: reasonController,
                        onChanged: onReasonChanged,
                        minLines: 2,
                        maxLines: 3,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: reasonPlaceholder ?? 'Enter reason...',
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF94A3B8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    )
                  else
                    KitchenPanelPermissionBanner(
                      message: resolvedPermissionNotice,
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          // Action Buttons
          KitchenPanelActions(
            backLabel: resolvedBackLabel,
            acknowledgeLabel: resolvedActionLabel,
            isQC: stateConfig.isQC,
            onClose: _handleDismiss,
            onBack: stateConfig.onBack,
            onAcknowledge: stateConfig.onAction,
            onPassQC: onPassQC ?? _handleDismiss,
            onFailQC: onFailQC,
            isAcknowledgeEnabled: stateConfig.isActionEnabled,
          ),
        ],
      ),
    );

    return panelWidget;
  }
}

/// Alias for [KitchenTicketDetailPanel].
typedef KitchenTicketPanel = KitchenTicketDetailPanel;
