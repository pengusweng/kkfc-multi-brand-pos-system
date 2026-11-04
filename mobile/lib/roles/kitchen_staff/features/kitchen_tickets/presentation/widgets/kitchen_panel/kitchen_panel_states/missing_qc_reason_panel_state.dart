import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/kitchen_panel_state_config.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/kitchen_panel_state_context.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

KitchenPanelStateConfig buildMissingQcReasonPanelState(
  KitchenPanelStateContext context,
) {
  return KitchenPanelStateConfig(
    badgeText: 'QC · CHECKER AUTHORIZATION PENDING',
    badgeColor: const Color(0xFF7C3AED),
    headerBackgroundColor: const Color(0xFFF7F3FD),
    topAccentColor: const Color(0xFF7C3AED),
    title: 'Reason required',
    subtitle: 'QC failure was not submitted',
    confirmTitle: 'CORRECT THE ERROR',
    confirmTitleColor: const Color(0xFF7C3AED),
    confirmItems: const [
      'Enter a reason before confirming',
      'Ticket remains in CHECKING',
    ],
    permissionNotice:
        'QC action shown as demo; approved checker rights required.',
    statusOverride: KkfcStatus.checking,
    backLabel: 'Back to QC',
    actionLabel: 'Submit reason',
    onBack: context.onBackToQC ?? context.onBack ?? context.dismiss,
    onAction:
        context.onSubmitReason ??
        context.onUseSampleReason ??
        context.onAcknowledge,
    showReasonField: true,
    isActionEnabled: true,
  );
}
